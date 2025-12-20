import 'dart:io';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:path/path.dart' as p;

/// {@template smart_merge_engine}
/// A Smart Merge Engine for merging user-edited code
/// with newly generated code, based on a common base snapshot.
/// {@endtemplate}
class MergeEngine {
  /// {@macro smart_merge_engine}
  MergeEngine() {
    // STRICT SETTINGS:
    // We disable fuzzy matching. In code generation,
    // "close enough" is dangerous.
    _dmp.matchThreshold = 0.0;
    _dmp.patchDeleteThreshold = 0.0;
    _dmp.patchMargin = 0;
  }

  final _dmp = DiffMatchPatch();
  bool? _hasGitCache;

  /// The Master Merge Function
  ///
  /// 1. Tries to use Git's native 'merge-file'
  /// (Best quality, handles complex conflicts).
  /// 2. Falls back to a strict Dart line-based merge
  /// (Safe, handles basic updates).
  String merge({
    required String base,
    required String mine,
    required String theirs,
  }) {
    if (base == mine) return theirs; // User hasn't changed anything.
    if (base == theirs) return mine; // Generator output didn't change.
    if (mine == theirs) return mine; // Already identical.

    // Strategy A: Git Merge (The "Pro" Way)
    if (_isGitAvailable()) {
      try {
        return _gitMerge3(base, mine, theirs);
      } on Exception catch (e) {
        stderr.writeln(
          'Warning: Git merge failed ($e). Falling back to Dart '
          'engine.',
        );
      }
    }

    // Strategy B: Dart Safe Merge (The Fallback)
    return _dartSafeMerge(base, mine, theirs);
  }

  // ===========================================================================
  // STRATEGY A: Git Native Merge
  // ===========================================================================

  bool _isGitAvailable() {
    if (_hasGitCache != null) return _hasGitCache!;
    try {
      final result = Process.runSync('git', ['--version']);
      _hasGitCache = result.exitCode == 0;
    } on Exception catch (_) {
      _hasGitCache = false;
    }
    return _hasGitCache!;
  }

  String _gitMerge3(String base, String mine, String theirs) {
    // Git requires physical files. We create temp ones.
    final tempDir = Directory.systemTemp.createTempSync('gen_merge_');
    try {
      final fileBase = File(p.join(tempDir.path, 'base'))
        ..writeAsStringSync(base);
      final fileMine = File(p.join(tempDir.path, 'mine'))
        ..writeAsStringSync(mine);
      final fileTheirs = File(p.join(tempDir.path, 'theirs'))
        ..writeAsStringSync(theirs);

      // COMMAND: git merge-file -p -L MINE -L BASE -L THEIRS mine base theirs
      final result = Process.runSync('git', [
        'merge-file',
        '-p', // Print to stdout
        '-L', 'MINE (Current Changes)',
        '-L', 'BASE (Ancestry)',
        '-L', 'THEIRS (Generator Update)',
        fileMine.path,
        fileBase.path,
        fileTheirs.path,
      ]);

      if (result.exitCode >= 0) {
        // Exit code 0 = clean merge. Exit code 1 = conflicts
        // (output has markers).
        return result.stdout.toString();
      }
      throw Exception('Git exited with code ${result.exitCode}');
    } finally {
      try {
        tempDir.deleteSync(recursive: true);
      } on Exception catch (_) {
        // Ignore cleanup errors
      }
    }
  }

  // ===========================================================================
  // STRATEGY B: Dart Strict Line-Based Merge
  // ===========================================================================

  String _dartSafeMerge(String base, String mine, String theirs) {
    // 1. Convert to Line-Mode (Treat lines as atomic blocks)
    // 1. Manually implement Line-to-Char conversion since the package hides it.
    // This maps every unique line to a unique unicode character.
    final lineMap = <String, String>{}; // Line content -> Unicode char
    final linesBase = _linesToChars(base, lineMap);
    final linesTheirs = _linesToChars(theirs, lineMap);

    // 2. Calculate Diffs & Patches
    final diffs = _dmp.diff(linesBase, linesTheirs, false);
    _charsToLines(diffs, lineMap);
    final patches = _dmp.patch(base, diffs);

    // 3. Apply manually
    return _applyPatchesGranularly(mine, patches);
  }

  /// Helper to map full lines to single characters for atomic diffing
  String _linesToChars(String text, Map<String, String> lineMap) {
    final buffer = StringBuffer();
    // Split by newline but keep the delimiter to preserve formatting
    // Dart's LineSplitter drops newlines, so we use a regex
    // lookbehind or manual split
    // Simple approach: split by \n and rejoin later, but that loses \r\n vs \n info.
    // Robust approach:
    var offset = 0;
    while (offset < text.length) {
      var nextNewline = text.indexOf('\n', offset);
      if (nextNewline == -1) nextNewline = text.length - 1;

      final line = text.substring(offset, nextNewline + 1);
      offset = nextNewline + 1;

      if (!lineMap.containsKey(line)) {
        // Use private use area chars to avoid collisions, or
        // just incrementing chars
        // Standard DMP uses unicode starting at 1.
        lineMap[line] = String.fromCharCode(lineMap.length + 1000);
      }
      buffer.write(lineMap[line]);
    }
    return buffer.toString();
  }

  /// Helper to convert the diffs back from chars to full lines
  void _charsToLines(List<Diff> diffs, Map<String, String> lineMap) {
    // Invert the map for lookup
    final charToLine = {for (final e in lineMap.entries) e.value: e.key};

    for (final diff in diffs) {
      final sb = StringBuffer();
      final text = diff.text;
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        sb.write(charToLine[char] ?? char);
      }
      diff.text = sb.toString();
    }
  }

  String _applyPatchesGranularly(String mine, List<Patch> patches) {
    var currentText = mine;
    // Reverse patches to maintain indices when injecting text
    final reversedPatches = List<Patch>.from(patches.reversed);

    for (final patch in reversedPatches) {
      // Try to apply strict
      final result = _dmp.patch_apply([patch], currentText);
      final patchedText = result[0] as String;
      final statusList = result[1] as List<bool>;
      final success = statusList.isNotEmpty && statusList[0];

      if (success) {
        currentText = patchedText;
      } else {
        // On failure, inject the full conflict block
        currentText = _injectConflict(currentText, patch);
      }
    }
    return currentText;
  }

  String _injectConflict(String text, Patch patch) {
    // Reconstruct what the generator wanted to add
    final theirsBlock = StringBuffer();

    for (final diff in patch.diffs) {
      if (diff.operation != 0) {
        // 0 is EQUAL, 1 is INSERT, -1 is DELETE
        // Note: The package usually defines Constants, but checking != 0
        // or != Operation.equal (if enums used) is safer.
        // Based on standard DMP, DELETE is -1, INSERT is 1.
        // We only care about what THEIRS adds or what MINE has.
        if (diff.operation == 1) {
          // Insert
          theirsBlock.write(diff.text);
        }
        // If it's a delete, we don't write it to "Theirs" block because
        // "Theirs" wants it gone.
      }
    }

    final marker =
        '\n<<<<<<< MINE (User modified this area)\n'
        '======= (Generator wanted to add/change:)\n'
        '${theirsBlock.toString().trim()}\n'
        '>>>>>>> THEIRS\n';

    // Insert at the approximate location
    final insertIndex = (patch.start1 < text.length)
        ? patch.start1
        : text.length;
    return text.substring(0, insertIndex) +
        marker +
        text.substring(insertIndex);
  }
}

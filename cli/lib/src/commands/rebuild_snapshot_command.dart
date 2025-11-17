import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// `clean_arch_cli rebuild-snapshot`
/// Removes a stale snapshot used by the global wrapper and forces a rebuild
/// (by invoking the wrapper), so the wrapper will run the up-to-date package
/// source.
class RebuildSnapshotCommand extends Command<int> {
  RebuildSnapshotCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'dry-run',
      help: 'Show what would be done without deleting or running anything',
    );
  }

  final Logger _logger;

  @override
  String get name => 'rebuild-snapshot';

  @override
  String get description {
    return 'Remove stale package snapshot used by the '
        'global wrapper and force a rebuild.';
  }

  @override
  Future<int> run() async {
    final dryRun = argResults!['dry-run'] as bool;

    _logger.info('🔧 Rebuilding global snapshot for $name...');

    // Find wrapper using `which` (POSIX)
    String? wrapperPath;
    try {
      final which = await Process.run('which', [name.replaceAll('-', '_')]);
      // some systems may not have an underscore name; try original
      if (which.exitCode == 0 && (which.stdout as String).trim().isNotEmpty) {
        wrapperPath = (which.stdout as String).trim();
      }
    } on Exception {
      // ignore
    }

    // Fallback: try the executable name directly
    wrapperPath ??= (await _whichExecutable()).trim();

    if (wrapperPath.isEmpty) {
      _logger.err('Could not locate global `$name` wrapper in PATH.');
      return ExitCode.software.code;
    }

    _logger.detail('Wrapper path: $wrapperPath');

    final wrapperFile = File(wrapperPath);
    if (!wrapperFile.existsSync()) {
      _logger.err('Wrapper script not found at: $wrapperPath');
      return ExitCode.software.code;
    }

    final wrapperContent = wrapperFile.readAsStringSync();

    // Try to extract the snapshot path from the common wrapper pattern
    final snapshotRegex = RegExp(r'if \[ -f ([^\s]+) \]; then', dotAll: true);
    final match = snapshotRegex.firstMatch(wrapperContent);
    String? snapshotPath;
    if (match != null && match.groupCount >= 1) {
      snapshotPath = match.group(1);
    } else {
      // try alternate quoting style
      final quotedRegex = RegExp(r"if \[ -f '([\w\-\./\_:\~]+)' \]; then");
      final m2 = quotedRegex.firstMatch(wrapperContent);
      if (m2 != null) snapshotPath = m2.group(1);
    }

    if (snapshotPath == null || snapshotPath.isEmpty) {
      _logger
        ..warn(
          'No snapshot path found inside wrapper; '
          'it may not be using a snapshot.',
        )
        ..info('Invoking wrapper to ensure latest package is used...');
      if (!dryRun) {
        await _invokeWrapper(wrapperPath);
      }
      return ExitCode.success.code;
    }

    _logger.info('Found snapshot path: $snapshotPath');

    final snapshotFile = File(snapshotPath);
    if (!snapshotFile.existsSync()) {
      _logger.info('Snapshot file does not exist (nothing to rebuild).');
      if (!dryRun) await _invokeWrapper(wrapperPath);
      return ExitCode.success.code;
    }

    if (dryRun) {
      _logger.info(
        'Dry run: would back up and remove $snapshotPath '
        'and then invoke wrapper.',
      );
      return ExitCode.success.code;
    }

    try {
      final bakPath =
          '$snapshotPath.bak.${DateTime.now().millisecondsSinceEpoch}';
      snapshotFile.renameSync(bakPath);
      _logger.info('Backed up snapshot to: $bakPath');
    } on Exception catch (e) {
      _logger.err('Failed to back up/remove snapshot: $e');
      return ExitCode.software.code;
    }

    _logger.info(
      'Invoking wrapper to rebuild the executable (this may take a moment)...',
    );
    await _invokeWrapper(wrapperPath);

    _logger.info(
      'Rebuild step complete. If you still see stale behavior, '
      'try `dart pub global activate --source=path <path-to-cli>`',
    );
    return ExitCode.success.code;
  }

  Future<void> _invokeWrapper(String wrapperPath) async {
    try {
      final proc = await Process.start(wrapperPath, ['--version']);
      // stream output
      proc.stdout
          .transform(const SystemEncoding().decoder)
          .listen((s) => _logger.info(s.trim()));
      proc.stderr
          .transform(const SystemEncoding().decoder)
          .listen((s) => _logger.err(s.trim()));
      final code = await proc.exitCode;
      if (code != 0) {
        _logger.err('Wrapper exited with code $code');
      }
    } on Exception catch (e) {
      _logger.err('Failed to invoke wrapper: $e');
    }
  }

  /// Attempt to locate the wrapper by running `which clean_arch_cli`.
  Future<String> _whichExecutable() async {
    try {
      final which = await Process.run('which', ['clean_arch_cli']);
      if (which.exitCode == 0) return which.stdout as String;
    } on Exception {
      // ignore
    }
    return '';
  }
}

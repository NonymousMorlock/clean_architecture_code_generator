import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// `clean_arch_cli rebuild-snapshot`
/// Removes all stale snapshots used by the global wrapper and forces a rebuild
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
    return 'Remove all stale package snapshots used by the '
        'global wrapper and force a rebuild.';
  }

  @override
  Future<int> run() async {
    final dryRun = argResults!['dry-run'] as bool;

    _logger.info('🔧 Rebuilding global snapshot for clean_arch_cli...');

    // Strategy 1: Delete all snapshots from .dart_tool directory
    final snapshotsDeleted = await _deleteAllSnapshots(dryRun: dryRun);

    // Strategy 2: Also find and handle wrapper-referenced snapshot
    final wrapperPath = await _findWrapperPath();

    if (wrapperPath.isEmpty) {
      if (snapshotsDeleted > 0) {
        _logger.success(
          '✅ Deleted $snapshotsDeleted snapshot file(s). '
          'Next invocation will recompile.',
        );
        return ExitCode.success.code;
      }
      _logger.warn('Could not locate global wrapper in PATH.');
      return ExitCode.software.code;
    }

    _logger.detail('Wrapper path: $wrapperPath');

    if (!dryRun) {
      _logger.info(
        'Invoking wrapper to rebuild the executable '
        '(this may take a moment)...',
      );
      await _invokeWrapper(wrapperPath);
    }

    _logger.success(
      '✅ Rebuild step complete. Deleted $snapshotsDeleted snapshot file(s). '
      'Stale code should now be resolved.',
    );
    return ExitCode.success.code;
  }

  /// Delete all snapshot files from .dart_tool/pub/bin/
  /// Returns the number of files deleted.
  Future<int> _deleteAllSnapshots({required bool dryRun}) async {
    var deletedCount = 0;

    // Find .dart_tool directory in common locations
    final possibleRoots = <String>[];

    // Add path from wrapper if we can extract it
    final wrapperPath = await _findWrapperPath();
    if (wrapperPath.isNotEmpty) {
      final wrapperFile = File(wrapperPath);
      if (wrapperFile.existsSync()) {
        final content = wrapperFile.readAsStringSync();
        final snapshotMatch = RegExp(
          r'if \[ -f ([^\s]+) \]; then',
          dotAll: true,
        ).firstMatch(content);

        if (snapshotMatch != null) {
          final snapshotPath = snapshotMatch.group(1);
          if (snapshotPath != null) {
            // Extract the .dart_tool/pub/bin directory
            final snapshotDir = path.dirname(snapshotPath);
            // Go up to .dart_tool/pub/bin (parent of 'cli')
            final dartToolBin = path.dirname(snapshotDir);
            possibleRoots.add(dartToolBin);
          }
        }
      }
    }

    // Add standard locations as fallbacks
    possibleRoots.add(
      path.join(
        Platform.environment['HOME'] ?? '',
        '.pub-cache',
        'global_packages',
        'clean_arch_cli',
        '.dart_tool',
        'pub',
        'bin',
      ),
    );

    for (final rootDir in possibleRoots) {
      _logger.detail('Scanning for snapshots in: $rootDir');
      final root = Directory(rootDir);
      if (!root.existsSync()) {
        _logger.detail('Directory does not exist: $rootDir');
        continue;
      }

      try {
        // Recursively find all snapshot files
        final files = root
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) =>
                  path.basename(f.path).endsWith('.snapshot') ||
                  path.basename(f.path).contains('.snapshot.'),
            )
            .toList();

        _logger.detail('Found ${files.length} snapshot file(s) in $rootDir');

        for (final file in files) {
          if (dryRun) {
            _logger.info('Dry run: would delete ${file.path}');
            deletedCount++;
          } else {
            try {
              file.deleteSync();
              _logger.detail(
                '🗑️  Deleted: ${path.relative(file.path, from: rootDir)}',
              );
              deletedCount++;
            } on Exception catch (e) {
              _logger.warn('Failed to delete ${file.path}: $e');
            }
          }
        }
      } on Exception catch (e) {
        _logger.detail('Could not scan $rootDir: $e');
      }
    }

    if (dryRun && deletedCount == 0) {
      _logger.info('Dry run: no snapshot files found to delete');
    } else if (!dryRun && deletedCount == 0) {
      _logger.detail('No snapshot files found to delete');
    }

    return deletedCount;
  }

  /// Find the wrapper path using `which`
  Future<String> _findWrapperPath() async {
    // Try with underscores first
    try {
      final which = await Process.run('which', ['clean_arch_cli']);
      if (which.exitCode == 0 && (which.stdout as String).trim().isNotEmpty) {
        return (which.stdout as String).trim();
      }
    } on Exception {
      // ignore
    }

    return '';
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
}

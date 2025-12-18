import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/config_reader.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template generate_command}
/// `clean_arch_cli generate` command to run code generation.
/// {@endtemplate}
class GenerateCommand extends Command<int> {
  /// {@macro generate_command}
  GenerateCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Path to the Flutter project (default: current directory)',
        defaultsTo: '.',
      )
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Watch for changes and regenerate automatically',
      )
      ..addFlag(
        'delete-conflicting-outputs',
        help: 'Delete conflicting outputs before generation',
      );
  }

  final Logger _logger;

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Run code generation for clean architecture components.\n\n'
      'Supports multi-file output mode (writes to actual feature files '
      'instead of .g.dart).\n'
      'Configure in clean_arch_config.yaml under multi_file_output.';

  @override
  Future<int> run() async {
    final projectPath = argResults!['path'] as String;
    final watch = argResults!['watch'] as bool;
    final deleteConflicting = argResults!['delete-conflicting-outputs'] as bool;

    _logger
      ..info('🔧 Running code generation...')
      // Diagnostic logs to help detect stale global binaries / wrong executable
      ..info('🔎 Dart executable: ${Platform.resolvedExecutable}')
      ..info('🔎 Script path: ${Platform.script.toFilePath()}')
      ..info('🔎 Current working directory: ${Directory.current.path}');

    // Check if pubspec.yaml exists
    final pubspecPath = '$projectPath/pubspec.yaml';
    if (!File(pubspecPath).existsSync()) {
      _logger
        ..err('❌ No pubspec.yaml found in $projectPath')
        ..info("Make sure you're in a Flutter project directory");
      return ExitCode.usage.code;
    }

    // Run flutter packages get first
    _logger.info('📦 Getting packages...');
    try {
      final getResult = await Process.run(
        'flutter',
        ['packages', 'get'],
        workingDirectory: projectPath,
      );

      if (getResult.exitCode != 0) {
        _logger.err('❌ Failed to get packages: ${getResult.stderr}');
        return ExitCode.software.code;
      }
    } on ProcessException catch (e) {
      _logger.err('❌ Failed to get packages: ${e.message}');
      return ExitCode.software.code;
    }

    // Build command arguments
    final buildArgs = ['packages', 'pub', 'run', 'build_runner', 'build'];

    if (watch) {
      buildArgs
        ..removeLast()
        ..add('watch');
    }

    if (deleteConflicting) {
      buildArgs.add('--delete-conflicting-outputs');
    }

    _logger.info('🚀 Running build_runner...');

    try {
      final buildProcess = await Process.start(
        'flutter',
        buildArgs,
        workingDirectory: projectPath,
      );

      // Stream output in real-time
      buildProcess.stdout.listen((data) {
        final output = String.fromCharCodes(data).trim();
        if (output.isNotEmpty) {
          _logger.info(output);
        }
      });

      buildProcess.stderr.listen((data) {
        final output = String.fromCharCodes(data).trim();
        if (output.isNotEmpty) {
          _logger.err(output);
        }
      });

      final exitCode = await buildProcess.exitCode;

      if (exitCode == 0) {
        try {
          if (!watch) {
            final isMultiFileEnabled = ConfigReader.isMultiFileEnabled(
              projectPath,
            );

            _logger.info(
              '🧹 Cleaning up output files '
              '(Multi-file mode: $isMultiFileEnabled)...',
            );

            final dir = Directory(projectPath);
            final filesToDelete = dir
                .listSync(recursive: true)
                .whereType<File>()
                .where((file) {
                  final path = file.path;
                  final isGFile = path.endsWith('.g.dart');
                  final isPartFile =
                      path.endsWith('.g.part') || path.endsWith('.part');

                  if (isMultiFileEnabled) {
                    // Delete everything generated in multi-file mode
                    return isGFile || isPartFile;
                  } else {
                    // Keep .g.dart files in single-file mode, only delete parts
                    return isPartFile;
                  }
                });

            for (final file in filesToDelete) {
              file.deleteSync();
            }
          }
        } on Exception catch (e) {
          _logger.err('❌ Failed to clean up output files: $e');
        }

        // run the dart format command on the directory
        _logger.info('🎨 Formatting generated code...');

        final formatResult = await Process.run(
          'dart',
          ['format', 'lib', 'test'],
          workingDirectory: projectPath,
        );

        if (formatResult.exitCode != 0) {
          _logger.err('❌ Failed to format code: ${formatResult.stderr}');
        }
        if (watch) {
          _logger.success('👀 Watching for changes... Press Ctrl+C to stop.');
        } else {
          _logger.success('✅ Code generation completed successfully!');
        }
        return ExitCode.success.code;
      } else {
        _logger.err('❌ Code generation failed with exit code $exitCode');
        return exitCode;
      }
    } on ProcessException catch (e) {
      _logger.err('❌ Failed to run build_runner: ${e.message}');
      return ExitCode.software.code;
    }
  }
}

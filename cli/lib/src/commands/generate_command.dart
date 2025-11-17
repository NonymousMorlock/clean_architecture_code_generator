import 'dart:io';

import 'package:args/command_runner.dart';
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

    _logger.info('🔧 Running code generation...');

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
    final getResult = await Process.run(
      'flutter',
      ['packages', 'get'],
      workingDirectory: projectPath,
    );

    if (getResult.exitCode != 0) {
      _logger.err('❌ Failed to get packages: ${getResult.stderr}');
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
  }
}

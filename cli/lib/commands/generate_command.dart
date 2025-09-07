import 'dart:io';
import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import '../clean_arch_cli.dart';

class GenerateCommand extends Command {
  GenerateCommand(super.logger);

  @override
  String get name => 'generate';

  @override
  String get description => 'Run code generation for clean architecture components';

  @override
  ArgParser get argParser => ArgParser()
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
      defaultsTo: false,
    )
    ..addFlag(
      'delete-conflicting-outputs',
      help: 'Delete conflicting outputs before generation',
      defaultsTo: false,
    );

  @override
  Future<void> run(ArgResults results) async {
    final projectPath = results['path'] as String;
    final watch = results['watch'] as bool;
    final deleteConflicting = results['delete-conflicting-outputs'] as bool;

    logger.info('🔧 Running code generation...');

    // Check if pubspec.yaml exists
    final pubspecPath = '$projectPath/pubspec.yaml';
    if (!await File(pubspecPath).exists()) {
      logger.err('❌ No pubspec.yaml found in $projectPath');
      logger.info('Make sure you\'re in a Flutter project directory');
      return;
    }

    // Run flutter packages get first
    logger.info('📦 Getting packages...');
    final getResult = await Process.run(
      'flutter',
      ['packages', 'get'],
      workingDirectory: projectPath,
    );

    if (getResult.exitCode != 0) {
      logger.err('❌ Failed to get packages: ${getResult.stderr}');
      return;
    }

    // Build command arguments
    final buildArgs = ['packages', 'pub', 'run', 'build_runner', 'build'];
    
    if (watch) {
      buildArgs.removeLast();
      buildArgs.add('watch');
    }
    
    if (deleteConflicting) {
      buildArgs.add('--delete-conflicting-outputs');
    }

    logger.info('🚀 Running build_runner...');
    
    final buildProcess = await Process.start(
      'flutter',
      buildArgs,
      workingDirectory: projectPath,
    );

    // Stream output in real-time
    buildProcess.stdout.listen((data) {
      final output = String.fromCharCodes(data).trim();
      if (output.isNotEmpty) {
        logger.info(output);
      }
    });

    buildProcess.stderr.listen((data) {
      final output = String.fromCharCodes(data).trim();
      if (output.isNotEmpty) {
        logger.err(output);
      }
    });

    final exitCode = await buildProcess.exitCode;

    if (exitCode == 0) {
      if (watch) {
        logger.success('👀 Watching for changes... Press Ctrl+C to stop.');
      } else {
        logger.success('✅ Code generation completed successfully!');
      }
    } else {
      logger.err('❌ Code generation failed with exit code $exitCode');
    }
  }
}

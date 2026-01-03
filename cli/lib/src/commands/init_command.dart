import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// {@template init_command}
/// `clean_arch_cli init` command to initialize a new Flutter project
/// with clean architecture setup.
/// {@endtemplate}
class InitCommand extends Command<int> {
  /// {@macro init_command}
  InitCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory (default: current directory)',
        defaultsTo: '.',
      )
      ..addFlag(
        'with-examples',
        help: 'Include example models and repositories',
        defaultsTo: true,
      );
  }

  final Logger _logger;

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize a new Flutter project with clean architecture setup';

  @override
  Future<int> run() async {
    final outputDir = argResults!['output'] as String;
    final withExamples = argResults!['with-examples'] as bool;

    _logger.info('🚀 Initializing Flutter project with clean architecture...');
    final pubspecPath = path.join(outputDir, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);
    if (pubspecFile.existsSync()) {
      final pubspecYamlString = pubspecFile.readAsStringSync();
      final pubspecYamlMap =
          loadYaml(pubspecYamlString) as Map<dynamic, dynamic>;
      final appName = pubspecYamlMap['name'] as String?;
      if (appName != null) {
        // Create clean architecture structure
        await _createCleanArchStructure(
          projectPath: outputDir,
          withExamples: withExamples,
          appName: appName,
        );
      } else {
        _logger.err('❌ Could not find project name in pubspec.yaml');
        return ExitCode.ioError.code;
      }
    } else {
      _logger.err('❌ Could not find pubspec.yaml');
      return ExitCode.ioError.code;
    }

    // Add dependencies
    await _addDependencies(outputDir);

    _logger
      ..success('🎉 Clean architecture project initialized successfully!')
      ..info('📁 Project created at: $outputDir')
      ..info('🔧 Run "flutter pub get" to install dependencies');

    return ExitCode.success.code;
  }

  Future<void> _createCleanArchStructure({
    required String projectPath,
    required String appName,
    required bool withExamples,
  }) async {
    final libPath = path.join(projectPath, 'lib');

    final brick = await _loadInitBrick();
    final generator = await MasonGenerator.fromBrick(brick);

    final coreTarget = DirectoryGeneratorTarget(Directory(libPath));

    await _generateFile(
      generator: generator,
      target: coreTarget,
      filePath: path.join('core', 'errors', 'failures.dart'),
      vars: {'appName': appName},
      appendIfExists: false,
    );

    await _generateFile(
      generator: generator,
      target: coreTarget,
      filePath: path.join('core', 'errors', 'exceptions.dart'),
      vars: {'appName': appName},
      appendIfExists: false,
    );

    await _generateFile(
      generator: generator,
      target: coreTarget,
      filePath: path.join('core', 'usecases', 'usecase.dart'),
      vars: {'appName': appName},
      appendIfExists: false,
    );

    await _generateFile(
      generator: generator,
      target: coreTarget,
      filePath: path.join('core', 'typedefs.dart'),
      vars: {'appName': appName},
      appendIfExists: true,
    );

    await _generateFile(
      generator: generator,
      target: DirectoryGeneratorTarget(Directory(projectPath)),
      filePath: 'clean_arch_config.yaml',
      vars: {'appName': appName},
      appendIfExists: false,
    );

    if (withExamples) {
      await _createSampleTbgFiles(
        generator: generator,
        libPath: libPath,
        appName: appName,
      );
    }
  }

  Future<void> _createSampleTbgFiles({
    required MasonGenerator generator,
    required String libPath,
    required String appName,
  }) async {
    final sampleDir = Directory(path.join(libPath, 'src', 'sample', 'tbg'));
    await sampleDir.create(recursive: true);

    final existingFiles = sampleDir.listSync().whereType<File>().toList();

    final templateFiles = [
      path.join('src', 'sample', 'tbg', 'auth_repository_tbg.dart'),
      path.join('src', 'sample', 'tbg', 'user_model_tbg.dart'),
    ];

    for (final relativePath in templateFiles) {
      final content = await _renderTemplate(
        generator: generator,
        filePath: relativePath,
        vars: {'appName': appName},
      );

      final alreadyPresent = existingFiles.any((file) {
        final existingContent = file.readAsStringSync();
        return existingContent.trim() == content.trim();
      });

      if (alreadyPresent) {
        _logger.detail(
          '⏭️ Skipped ${path.basename(relativePath)} (already present)',
        );
        continue;
      }

      final destinationFile = await _nextAvailableSampleFile(sampleDir);
      await destinationFile.writeAsString(content);
      existingFiles.add(destinationFile);
      _logger.detail(
        '✅ Added sample TBG: ${path.basename(destinationFile.path)}',
      );
    }
  }

  Future<File> _nextAvailableSampleFile(Directory directory) async {
    var index = 0;
    while (true) {
      final fileName = index == 0
          ? 'sample_tbg.dart'
          : 'sample_tbg_${index + 1}.dart';
      final candidate = File(path.join(directory.path, fileName));
      if (!candidate.existsSync()) {
        return candidate;
      }
      index++;
    }
  }

  Future<Brick> _loadInitBrick() async {
    final packageUri = await Isolate.resolvePackageUri(
      Uri.parse('package:clean_arch_cli/src/commands/init_command.dart'),
    );

    if (packageUri == null) {
      throw Exception('Could not resolve package URI for templates');
    }

    final packageRoot = path.normalize(
      path.join(path.dirname(packageUri.toFilePath()), '..', '..', '..'),
    );
    final brickPath = path.join(packageRoot, 'bricks', 'init');

    return Brick.path(brickPath);
  }

  Future<void> _generateFile({
    required MasonGenerator generator,
    required DirectoryGeneratorTarget target,
    required String filePath,
    required Map<String, dynamic> vars,
    required bool appendIfExists,
  }) async {
    final rendered = await _renderTemplate(
      generator: generator,
      filePath: filePath,
      vars: vars,
    );

    final destination = File(path.join(target.dir.path, filePath));

    final relativePath = path.relative(destination.path, from: target.dir.path);

    if (destination.existsSync()) {
      if (!appendIfExists) {
        _logger.detail(
          '⏭️ Skipped $relativePath (already exists)',
        );
        return;
      }

      final existingContent = await destination.readAsString();
      if (existingContent.contains(rendered.trim())) {
        _logger.detail(
          '⏭️ Skipped $relativePath (already present)',
        );
        return;
      }

      final updatedContent = '${existingContent.trimRight()}\n\n$rendered';
      await destination.writeAsString(updatedContent);
      _logger.detail(
        '➕ Appended $relativePath',
      );
      return;
    }

    await destination.create(recursive: true);
    await destination.writeAsString(rendered);
    _logger.detail(
      '✅ Created $relativePath',
    );
  }

  Future<String> _renderTemplate({
    required MasonGenerator generator,
    required String filePath,
    required Map<String, dynamic> vars,
  }) async {
    final target = _MemoryGeneratorTarget();
    await generator.generate(
      target,
      vars: vars,
    );

    final normalizedTarget = path.normalize(filePath);
    final file = target.files.firstWhere(
      (f) {
        final generatedPath = path.normalize(f.path);
        return generatedPath == normalizedTarget ||
            generatedPath.endsWith(normalizedTarget);
      },
      orElse: () => throw Exception('Template not found for $filePath'),
    );

    return file.contentAsString();
  }

  Future<void> _addDependencies(String projectPath) async {
    try {
      final addStandardDependencies = await Process.run(
        'flutter',
        [
          'pub',
          'add',
          'dev:build_runner',
          'dev:mocktail',
        ],
        workingDirectory: projectPath,
      );
      if (addStandardDependencies.exitCode != 0) {
        _logger.err(
          '❌ Failed to add dependencies: ${addStandardDependencies.stderr}',
        );
      } else {
        _logger.detail('✅ Added build_runner and mocktail');
      }
    } on ProcessException catch (e) {
      _logger.err('❌ Failed to add dependencies: $e');
    }

    final hasGenerators = await _hasGeneratorsDependency(projectPath);
    if (hasGenerators) {
      _logger.detail('⏭️ Skipped generators (already present)');
      return;
    }

    const generatorEntrySnippet =
        'Add this to your pubspec.yaml manually:\n'
        'dev_dependencies:\n'
        '  generators:\n'
        '    git:\n'
        '      url: https://github.com/NonymousMorlock/clean_architecture_code_generator.git\n'
        '      path: generators';

    try {
      final addGenerators = await Process.run(
        'flutter',
        [
          'pub',
          'add',
          'dev:generators',
          '--git-url=https://github.com/NonymousMorlock/clean_architecture_code_generator.git',
          '--git-path=generators',
        ],
        workingDirectory: projectPath,
      );

      final stderr = addGenerators.stderr?.toString() ?? '';
      if (addGenerators.exitCode == 0) {
        _logger.detail('✅ Added generators dependency');
        return;
      }

      final generatorsNowPresent =
          stderr.contains('already depends on "generators"') ||
          await _hasGeneratorsDependency(projectPath);

      if (generatorsNowPresent) {
        _logger.detail('⏭️ Skipped generators (already present)');
        return;
      }

      _logger
        ..warn('⚠️ Failed to add generators: $stderr')
        ..info(generatorEntrySnippet);
    } on ProcessException catch (e) {
      final generatorsNowPresent = await _hasGeneratorsDependency(projectPath);
      if (generatorsNowPresent) {
        _logger.detail('⏭️ Skipped generators (already present)');
        return;
      }

      _logger
        ..warn('⚠️ Failed to add generators: $e')
        ..info(generatorEntrySnippet);
    }
  }
}

class _MemoryGeneratedFile {
  _MemoryGeneratedFile({
    required this.path,
    required this.bytes,
  });

  final String path;
  final List<int> bytes;

  String contentAsString() => utf8.decode(bytes);
}

class _MemoryGeneratorTarget extends GeneratorTarget {
  _MemoryGeneratorTarget() : files = [];

  final List<_MemoryGeneratedFile> files;

  @override
  Future<GeneratedFile> createFile(
    String filePath,
    List<int> contents, {
    Logger? logger,
    OverwriteRule? overwriteRule,
  }) async {
    files.add(_MemoryGeneratedFile(path: filePath, bytes: contents));
    return GeneratedFile.created(path: filePath);
  }
}

Future<bool> _hasGeneratorsDependency(String projectPath) async {
  final pubspecPath = path.join(projectPath, 'pubspec.yaml');
  final pubspecFile = File(pubspecPath);
  if (!pubspecFile.existsSync()) return false;

  try {
    final pubspecYamlString = await pubspecFile.readAsString();
    final pubspecYamlMap =
        loadYaml(pubspecYamlString) as Map<dynamic, dynamic>? ?? {};
    final devDeps = pubspecYamlMap['dev_dependencies'];
    if (devDeps is Map && devDeps.containsKey('generators')) {
      return true;
    }
  } on Exception catch (_) {
    // Ignore parse errors; treat as missing.
  }

  return false;
}

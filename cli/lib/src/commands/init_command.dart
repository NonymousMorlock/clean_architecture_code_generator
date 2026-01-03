import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
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

    // Core directories
    final directories = [
      'core/errors',
      'core/usecases',
    ];

    for (final dir in directories) {
      final dirPath = path.join(libPath, dir);
      await Directory(dirPath).create(recursive: true);
      _logger.detail('📁 Created: $dir');
    }

    // Create core files
    await _createCoreFiles(libPath);

    if (withExamples) {
      await _createExampleFiles(libPath);
    }
  }

  Future<void> _createCoreFiles(String libPath) async {
    // Create typedefs.dart
    const typedefsContent = '''
typedef DataMap = Map<String, dynamic>;
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;
''';
    await File(
      path.join(libPath, 'core', 'typedefs.dart'),
    ).writeAsString(typedefsContent);

    // Create failures.dart
    const failuresContent = '''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  List<Object> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, required super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, required super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, required super.statusCode});
}
''';
    await File(
      path.join(libPath, 'core', 'errors', 'failures.dart'),
    ).writeAsString(failuresContent);

    // Create exceptions.dart
    const exceptionsContent = '''
class ServerException implements Exception {
  const ServerException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;
}

class CacheException implements Exception {
  const CacheException({required this.message, required this.statusCode});
}

class NetworkException implements Exception {
  const NetworkException({required this.message, required this.statusCode});
}
''';
    await File(
      path.join(libPath, 'core', 'errors', 'exceptions.dart'),
    ).writeAsString(exceptionsContent);

    // Create usecase.dart
    const usecaseContent = '''
import '../typedefs.dart';

abstract class UsecaseWithParams<Type, Params> {
  const UsecaseWithParams();
  
  ResultFuture<Type> call(Params params);
}

abstract class UsecaseWithoutParams<Type> {
  const UsecaseWithoutParams();
  
  ResultFuture<Type> call();
}

abstract class StreamUsecaseWithParams<Type, Params> {
  const StreamUsecaseWithParams();
  
  ResultStream<Type> call(Params params);
}

abstract class StreamUsecaseWithoutParams<Type> {
  const StreamUsecaseWithoutParams();
  
  ResultStream<Type> call();
}
''';
    await File(
      path.join(libPath, 'core', 'usecases', 'usecase.dart'),
    ).writeAsString(usecaseContent);

    _logger.detail('✅ Created core files');
  }

  Future<void> _createExampleFiles(String libPath) async {
    // Create example auth entity
    const authEntityContent = '''
import 'package:annotations/annotations.dart';

@entityGen
@modelGen
class UserTBG {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
}
''';
    await File(
      path.join(
        libPath,
        'features',
        'authentication',
        'domain',
        'entities',
        'user.dart',
      ),
    ).writeAsString(authEntityContent);

    // Create example repository interface
    const authRepoContent = '''
import 'package:annotations/annotations.dart';
import '../entities/user.dart';
import '../../../../core/typedefs.dart';

@repoGen
@usecaseGen
@repoImplGen
@remoteSrcGen
@localSrcGen
class AuthRepoTBG {
  external ResultFuture<User> login({required String email, required String password});
  external ResultFuture<User> register({required String email, required String password, required String name});
  external ResultFuture<void> logout();
  external ResultFuture<User> getCurrentUser();
}
''';
    await File(
      path.join(
        libPath,
        'features',
        'authentication',
        'auth_repository_tbg.dart',
      ),
    ).writeAsString(authRepoContent);

    _logger.detail('✅ Created example files');
  }

  Future<void> _addDependencies(String projectPath) async {
    var wasCLISuccessful = true;
    try {
      final addDependencies = await Process.run(
        'flutter',
        [
          'pub',
          'add',
          'dev:build_runner',
          'dev:mocktail',
          'dev:generators',
          '--git-url=https://github.com/NonymousMorlock/clean_architecture_code_generator.git',
          '--git-path=generators',
        ],
        workingDirectory: projectPath,
      );
      if (addDependencies.exitCode != 0) {
        _logger.err('❌ Failed to add dependencies: ${addDependencies.stderr}');
        wasCLISuccessful = false;
      } else {
        _logger.detail('✅ Added dependencies');
      }
    } on ProcessException catch (e) {
      _logger.err('❌ Failed to add dependencies: $e');
      wasCLISuccessful = false;
    }
    if (!wasCLISuccessful) {
      final pubspecPath = path.join(projectPath, 'pubspec.yaml');
      final pubspecContent = await File(pubspecPath).readAsString();

      const additionalDependencies = '''
dev_dependencies:
  build_runner: any
  generators:
    git:
      url: https://github.com/NonymousMorlock/clean_architecture_code_generator.git
      path: generators
  mocktail: any
  ''';

      final updatedContent = pubspecContent.replaceFirst(
        'dev_dependencies:',
        '$additionalDependencies\ndev_dependencies:',
      );

      await File(pubspecPath).writeAsString(updatedContent);
      _logger.detail('✅ Added dependencies to pubspec.yaml');
    }
  }
}

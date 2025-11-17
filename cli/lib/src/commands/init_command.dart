import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// {@template init_command}
/// `clean_arch_cli init` command to initialize a new Flutter project
/// with clean architecture setup.
/// {@endtemplate}
class InitCommand extends Command<int> {
  /// {@macro init_command}
  InitCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'project-name',
        abbr: 'n',
        help: 'Name of the Flutter project',
        mandatory: true,
      )
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
    final projectName = argResults!['project-name'] as String;
    final outputDir = argResults!['output'] as String;
    final withExamples = argResults!['with-examples'] as bool;

    _logger.info('🚀 Initializing Flutter project with clean architecture...');

    final projectPath = path.join(outputDir, projectName);

    // Create Flutter project
    try {
      final createResult = await Process.run(
        'flutter',
        ['create', projectName],
        workingDirectory: outputDir,
      );

      if (createResult.exitCode != 0) {
        _logger.err('Failed to create Flutter project: ${createResult.stderr}');
        return ExitCode.software.code;
      }
    } on ProcessException catch (e) {
      _logger.err('Failed to create Flutter project: ${e.message}');
      return ExitCode.software.code;
    }

    _logger.success('✅ Flutter project created');

    // Create clean architecture structure
    await _createCleanArchStructure(projectPath, projectName, withExamples);

    // Add dependencies
    await _addDependencies(projectPath);

    _logger
      ..success('🎉 Clean architecture project initialized successfully!')
      ..info('📁 Project created at: $projectPath')
      ..info('🔧 Run "flutter pub get" to install dependencies');

    return ExitCode.success.code;
  }

  Future<void> _createCleanArchStructure(
    String projectPath,
    String projectName,
    bool withExamples,
  ) async {
    final libPath = path.join(projectPath, 'lib');

    // Core directories
    final directories = [
      'core/constants',
      'core/errors',
      'core/network',
      'core/usecases',
      'core/utils',
      'injection_container',
    ];

    if (withExamples) {
      directories.addAll([
        'features/authentication/data/datasources',
        'features/authentication/data/models',
        'features/authentication/data/repositories',
        'features/authentication/domain/entities',
        'features/authentication/domain/repositories',
        'features/authentication/domain/usecases',
        'features/authentication/presentation/bloc',
        'features/authentication/presentation/pages',
        'features/authentication/presentation/widgets',
      ]);
    }

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
        'domain',
        'repositories',
        'auth_repository.dart',
      ),
    ).writeAsString(authRepoContent);

    _logger.detail('✅ Created example files');
  }

  Future<void> _addDependencies(String projectPath) async {
    final pubspecPath = path.join(projectPath, 'pubspec.yaml');
    final pubspecContent = await File(pubspecPath).readAsString();

    const additionalDependencies = '''
  # Clean Architecture Dependencies
  equatable: ^2.0.5
  dartz: ^0.10.1
  get_it: ^7.6.4
  shared_preferences: ^2.2.2
  dio: ^5.3.2
  bloc: ^8.1.2
  flutter_bloc: ^8.1.3
  
  # Code Generation
  annotations:
    path: ../annotations
  generators:
    path: ../generators

dev_dependencies:
  build_runner: ^2.4.7
  json_annotation: ^4.8.1
''';

    final updatedContent = pubspecContent.replaceFirst(
      'dev_dependencies:',
      '$additionalDependencies\ndev_dependencies:',
    );

    await File(pubspecPath).writeAsString(updatedContent);
    _logger.detail('✅ Added dependencies to pubspec.yaml');
  }
}

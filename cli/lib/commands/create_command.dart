import 'dart:io';
import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import '../clean_arch_cli.dart';

class CreateCommand extends Command {
  CreateCommand(super.logger);

  @override
  String get name => 'create';

  @override
  String get description => 'Create clean architecture components (feature, entity, repository, etc.)';

  @override
  ArgParser get argParser => ArgParser()
    ..addOption(
      'type',
      abbr: 't',
      help: 'Type of component to create',
      allowed: ['feature', 'entity', 'repository', 'usecase', 'cubit'],
      mandatory: true,
    )
    ..addOption(
      'name',
      abbr: 'n',
      help: 'Name of the component',
      mandatory: true,
    )
    ..addOption(
      'feature',
      abbr: 'f',
      help: 'Feature name (required for non-feature components)',
    )
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Project path (default: current directory)',
      defaultsTo: '.',
    );

  @override
  Future<void> run(ArgResults results) async {
    final type = results['type'] as String;
    final name = results['name'] as String;
    final feature = results['feature'] as String?;
    final projectPath = results['path'] as String;

    if (type != 'feature' && feature == null) {
      logger.err('❌ Feature name is required for $type creation');
      logger.info('Use --feature to specify the feature name');
      return;
    }

    logger.info('🏗️  Creating $type: $name');

    switch (type) {
      case 'feature':
        await _createFeature(projectPath, name);
        break;
      case 'entity':
        await _createEntity(projectPath, feature!, name);
        break;
      case 'repository':
        await _createRepository(projectPath, feature!, name);
        break;
      case 'usecase':
        await _createUsecase(projectPath, feature!, name);
        break;
      case 'cubit':
        await _createCubit(projectPath, feature!, name);
        break;
    }

    logger.success('✅ $type created successfully!');
    logger.info('🔧 Run "clean_arch_cli generate" to generate code');
  }

  Future<void> _createFeature(String projectPath, String featureName) async {
    final libPath = path.join(projectPath, 'lib');
    final featurePath = path.join(libPath, 'features', featureName);

    final directories = [
      'data/datasources',
      'data/models',
      'data/repositories',
      'domain/entities',
      'domain/repositories',
      'domain/usecases',
      'presentation/bloc',
      'presentation/pages',
      'presentation/widgets',
    ];

    for (final dir in directories) {
      final dirPath = path.join(featurePath, dir);
      await Directory(dirPath).create(recursive: true);
      logger.detail('📁 Created: features/$featureName/$dir');
    }
  }

  Future<void> _createEntity(String projectPath, String featureName, String entityName) async {
    final entityPath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'domain',
      'entities',
      '${entityName.toLowerCase()}.dart',
    );

    final content = '''
import 'package:annotations/annotations.dart';

@entityGen
@modelGen
class ${_toPascalCase(entityName)}TBG {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // TODO: Add your entity properties here
}
''';

    await File(entityPath).writeAsString(content);
    logger.detail('📄 Created entity: ${entityName.toLowerCase()}.dart');
  }

  Future<void> _createRepository(String projectPath, String featureName, String repoName) async {
    final repoPath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'domain',
      'repositories',
      '${repoName.toLowerCase()}_repository.dart',
    );

    final content = '''
import 'package:annotations/annotations.dart';
import '../../../../core/typedefs.dart';
import '../entities/${repoName.toLowerCase()}.dart';

@repoGen
@usecaseGen
@repoImplGen
@remoteSrcGen
@localSrcGen
class ${_toPascalCase(repoName)}RepoTBG {
  external ResultFuture<${_toPascalCase(repoName)}> get${_toPascalCase(repoName)}(String id);
  external ResultFuture<List<${_toPascalCase(repoName)}>> get${_toPascalCase(repoName)}s();
  external ResultFuture<${_toPascalCase(repoName)}> create${_toPascalCase(repoName)}(${_toPascalCase(repoName)} ${repoName.toLowerCase()});
  external ResultFuture<${_toPascalCase(repoName)}> update${_toPascalCase(repoName)}(${_toPascalCase(repoName)} ${repoName.toLowerCase()});
  external ResultFuture<void> delete${_toPascalCase(repoName)}(String id);
}
''';

    await File(repoPath).writeAsString(content);
    logger.detail('📄 Created repository: ${repoName.toLowerCase()}_repository.dart');
  }

  Future<void> _createUsecase(String projectPath, String featureName, String usecaseName) async {
    final usecasePath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'domain',
      'usecases',
      '${usecaseName.toLowerCase()}.dart',
    );

    final content = '''
import '../../../../core/usecases/usecase.dart';
import '../../../../core/typedefs.dart';
import '../repositories/${featureName.toLowerCase()}_repository.dart';

class ${_toPascalCase(usecaseName)} extends UsecaseWithoutParams<void> {
  const ${_toPascalCase(usecaseName)}(this._repository);

  final ${_toPascalCase(featureName)}Repo _repository;

  @override
  ResultFuture<void> call() => _repository.${usecaseName.toLowerCase()}();
}
''';

    await File(usecasePath).writeAsString(content);
    logger.detail('📄 Created usecase: ${usecaseName.toLowerCase()}.dart');
  }

  Future<void> _createCubit(String projectPath, String featureName, String cubitName) async {
    final cubitPath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'presentation',
      'bloc',
      '${cubitName.toLowerCase()}_cubit.dart',
    );

    final statePath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'presentation',
      'bloc',
      '${cubitName.toLowerCase()}_state.dart',
    );

    final cubitContent = '''
import 'package:annotations/annotations.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_${featureName.toLowerCase()}.dart';

part '${cubitName.toLowerCase()}_state.dart';

@cubitGen
class ${_toPascalCase(cubitName)}CubitTBG extends Cubit<${_toPascalCase(cubitName)}State> {
  ${_toPascalCase(cubitName)}CubitTBG({
    required Get${_toPascalCase(featureName)} get${_toPascalCase(featureName)},
  }) : _get${_toPascalCase(featureName)} = get${_toPascalCase(featureName)},
       super(const ${_toPascalCase(cubitName)}Initial());

  final Get${_toPascalCase(featureName)} _get${_toPascalCase(featureName)};

  Future<void> get${_toPascalCase(featureName)}() async {
    emit(const ${_toPascalCase(cubitName)}Loading());

    final result = await _get${_toPascalCase(featureName)}();

    result.fold(
      (failure) => emit(${_toPascalCase(cubitName)}Error.fromFailure(failure)),
      (data) => emit(${_toPascalCase(cubitName)}Loaded(data)),
    );
  }
}
''';

    final stateContent = '''
part of '${cubitName.toLowerCase()}_cubit.dart';

sealed class ${_toPascalCase(cubitName)}State extends Equatable {
  const ${_toPascalCase(cubitName)}State();

  @override
  List<Object> get props => [];
}

final class ${_toPascalCase(cubitName)}Initial extends ${_toPascalCase(cubitName)}State {
  const ${_toPascalCase(cubitName)}Initial();
}

final class ${_toPascalCase(cubitName)}Loading extends ${_toPascalCase(cubitName)}State {
  const ${_toPascalCase(cubitName)}Loading();
}

final class ${_toPascalCase(cubitName)}Loaded extends ${_toPascalCase(cubitName)}State {
  const ${_toPascalCase(cubitName)}Loaded(this.data);

  final dynamic data; // TODO: Replace with actual data type

  @override
  List<Object> get props => [data];
}

final class ${_toPascalCase(cubitName)}Error extends ${_toPascalCase(cubitName)}State {
  const ${_toPascalCase(cubitName)}Error({required this.message, required this.title});

  ${_toPascalCase(cubitName)}Error.fromFailure(Failure failure)
    : this(message: failure.message, title: 'Error \${failure.statusCode}');

  final String message;
  final String title;

  @override
  List<String> get props => [message, title];
}
''';

    await File(cubitPath).writeAsString(cubitContent);
    await File(statePath).writeAsString(stateContent);
    
    logger.detail('📄 Created cubit: ${cubitName.toLowerCase()}_cubit.dart');
    logger.detail('📄 Created state: ${cubitName.toLowerCase()}_state.dart');
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }
}

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// {@template create_command}
/// `clean_arch_cli create` command to create clean architecture components.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: 'Type of component to create',
        allowed: ['feature', 'entity', 'repository', 'usecase', 'adapter'],
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
  }

  final Logger _logger;

  @override
  String get name => 'create';

  @override
  String get description =>
      'Create clean architecture components '
      '(feature, entity, repository, etc.).\n\n'
      'Supports feature scaffolding from YAML config '
      '(auto-generates files from defined methods).\n'
      'Configure in clean_arch_config.yaml under feature_scaffolding.';

  @override
  Future<int> run() async {
    final type = argResults!['type'] as String;
    final name = argResults!['name'] as String;
    final feature = argResults!['feature'] as String?;
    final projectPath = argResults!['path'] as String;

    if (type != 'feature' && feature == null) {
      _logger
        ..err('❌ Feature name is required for $type creation')
        ..info('Use --feature to specify the feature name');
      return ExitCode.usage.code;
    }

    _logger.info('🏗️  Creating $type: $name');

    switch (type) {
      case 'feature':
        await _createFeature(projectPath, name);
      case 'entity':
        await _createEntity(projectPath, feature!, name);
      case 'repository':
        await _createRepository(projectPath, feature!, name);
      case 'usecase':
        await _createUsecase(projectPath, feature!, name);
      case 'adapter':
        await _createAdapter(projectPath, feature!, name);
    }

    _logger
      ..success('✅ $type created successfully!')
      ..info('🔧 Run "clean_arch_cli generate" to generate code');

    return ExitCode.success.code;
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
      'presentation/adapter',
      'presentation/pages',
      'presentation/widgets',
    ];

    for (final dir in directories) {
      final dirPath = path.join(featurePath, dir);
      await Directory(dirPath).create(recursive: true);
      _logger.detail('📁 Created: features/$featureName/$dir');
    }
  }

  Future<void> _createEntity(
    String projectPath,
    String featureName,
    String entityName,
  ) async {
    final entityPath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'domain',
      'entities',
      '${entityName.toLowerCase()}.dart',
    );

    final content =
        '''
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
    _logger.detail('📄 Created entity: ${entityName.toLowerCase()}.dart');
  }

  Future<void> _createRepository(
    String projectPath,
    String featureName,
    String repoName,
  ) async {
    final repoPath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'domain',
      'repositories',
      '${repoName.toLowerCase()}_repository.dart',
    );

    final content =
        '''
import 'package:annotations/annotations.dart';
import '../../../../core/typedefs.dart';
import '../entities/${repoName.toLowerCase()}.dart';

part '${repoName.toLowerCase()}_repository.g.dart';

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
    _logger.detail(
      '📄 Created repository: ${repoName.toLowerCase()}_repository.dart',
    );
  }

  Future<void> _createUsecase(
    String projectPath,
    String featureName,
    String usecaseName,
  ) async {
    final usecasePath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'domain',
      'usecases',
      '${usecaseName.toLowerCase()}.dart',
    );

    final content =
        '''
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
    _logger.detail('📄 Created usecase: ${usecaseName.toLowerCase()}.dart');
  }

  Future<void> _createAdapter(
    String projectPath,
    String featureName,
    String adapterName,
  ) async {
    final adapterPath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'presentation',
      'adapter',
      '${adapterName.toLowerCase()}_adapter.dart',
    );

    final statePath = path.join(
      projectPath,
      'lib',
      'features',
      featureName,
      'presentation',
      'adapter',
      '${adapterName.toLowerCase()}_state.dart',
    );

    final adapterContent =
        '''
import 'package:annotations/annotations.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_${featureName.toLowerCase()}.dart';

part '${adapterName.toLowerCase()}_state.dart';

@adapterGen
class ${_toPascalCase(adapterName)}AdapterTBG extends Cubit<${_toPascalCase(adapterName)}State> {
  ${_toPascalCase(adapterName)}AdapterTBG({
    required Get${_toPascalCase(featureName)} get${_toPascalCase(featureName)},
  }) : _get${_toPascalCase(featureName)} = get${_toPascalCase(featureName)},
       super(const ${_toPascalCase(adapterName)}Initial());

  final Get${_toPascalCase(featureName)} _get${_toPascalCase(featureName)};

  Future<void> get${_toPascalCase(featureName)}() async {
    emit(const ${_toPascalCase(adapterName)}Loading());

    final result = await _get${_toPascalCase(featureName)}();

    result.fold(
      (failure) => emit(${_toPascalCase(adapterName)}Error.fromFailure(failure)),
      (data) => emit(${_toPascalCase(adapterName)}Loaded(data)),
    );
  }
}
''';

    final stateContent =
        '''
part of '${adapterName.toLowerCase()}_adapter.dart';

sealed class ${_toPascalCase(adapterName)}State extends Equatable {
  const ${_toPascalCase(adapterName)}State();

  @override
  List<Object> get props => [];
}

final class ${_toPascalCase(adapterName)}Initial extends ${_toPascalCase(adapterName)}State {
  const ${_toPascalCase(adapterName)}Initial();
}

final class ${_toPascalCase(adapterName)}Loading extends ${_toPascalCase(adapterName)}State {
  const ${_toPascalCase(adapterName)}Loading();
}

final class ${_toPascalCase(adapterName)}Loaded extends ${_toPascalCase(adapterName)}State {
  const ${_toPascalCase(adapterName)}Loaded(this.data);

  final dynamic data; // TODO: Replace with actual data type

  @override
  List<Object> get props => [data];
}

final class ${_toPascalCase(adapterName)}Error extends ${_toPascalCase(adapterName)}State {
  const ${_toPascalCase(adapterName)}Error({required this.message, required this.title});

  ${_toPascalCase(adapterName)}Error.fromFailure(Failure failure)
    : this(message: failure.message, title: 'Error \${failure.statusCode}');

  final String message;
  final String title;

  @override
  List<String> get props => [message, title];
}
''';

    await File(adapterPath).writeAsString(adapterContent);
    await File(statePath).writeAsString(stateContent);

    _logger
      ..detail('📄 Created adapter: ${adapterName.toLowerCase()}_adapter.dart')
      ..detail('📄 Created state: ${adapterName.toLowerCase()}_state.dart');
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }
}

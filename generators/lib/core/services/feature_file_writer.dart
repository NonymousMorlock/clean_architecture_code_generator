// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:generators/generators.dart';
import 'package:path/path.dart' as path;

/// A typedef for the result of a smart import generation.
typedef ImportResult = ({List<String> imports, List<String> importComments});

/// Service for resolving and writing generated code to feature files
/// instead of .g.dart files when multi-file output is enabled.
class FeatureFileWriter {
  /// Creates a [FeatureFileWriter] with the given configuration and build step.
  FeatureFileWriter({required this.config, required this.buildStep});

  /// The generator configuration.
  final GeneratorConfig config;

  /// The current build step.
  final BuildStep buildStep;

  /// Determines if multi-file output is enabled
  bool get isMultiFileEnabled => config.multiFileOutput.enabled;

  /// Determines if auto-creation of missing files is enabled
  bool get shouldAutoCreate => config.multiFileOutput.autoCreateTargets;

  /// Extract feature name from the build step input path
  /// e.g., lib/features/auth/domain/repositories/auth_repository.dart -> auth
  String? extractFeatureName({String? repoName}) {
    final inputPath = buildStep.inputId.path;
    final parts = inputPath.split('/');

    final rootName = config.featureScaffolding.rootName;

    final idx = parts.indexOf(rootName);
    if (idx != -1 && idx + 1 < parts.length) {
      return parts[idx + 1];
    }

    // otherwise, I'll look in the repo name and remove the "repo part"
    if (repoName != null) {
      final repoBaseName = extractBaseName(repoName);
      return repoBaseName;
    }

    return null;
  }

  /// Extract the base name from a repository class name
  /// e.g., AuthRepoTBG -> auth, UserRepoTBG -> user
  String extractBaseName(String repoClassName) {
    return repoClassName
        .replaceAll('TBG', 'replace')
        .replaceAll('Repo', '')
        .replaceAll('Cubit', '')
        .replaceAll('Adapter', '')
        .snakeCase;
  }

  /// Get the feature root directory path
  /// e.g., lib/features/auth
  String getFeatureRoot(String featureName) {
    return path.join(
      config.outputPath,
      config.featureScaffolding.rootName,
      featureName.snakeCase,
    );
  }

  /// Get the feature package path
  /// e.g., my_app/features/auth
  String getFeaturePackagePath(String featureName) {
    return '${config.appName}/${config.featureScaffolding.rootName}/${featureName.snakeCase}';
  }

  /// Get the domain repository file path
  /// e.g., lib/features/auth/domain/repositories/auth_repository.dart
  String getDomainRepoPath(String featureName) {
    return path.join(
      getFeatureRoot(featureName.snakeCase),
      'domain',
      'repositories',
      '${featureName.snakeCase}_repository.dart',
    );
  }

  /// Get the usecase file path for a specific method
  /// e.g., lib/features/auth/domain/usecases/register.dart
  String getUsecasePath(String featureName, String methodName) {
    return path.join(
      getFeatureRoot(featureName.snakeCase),
      'domain',
      'usecases',
      '${methodName.snakeCase}.dart',
    );
  }

  /// Get the remote data source file path
  /// e.g., lib/features/auth/data/datasources/auth_remote_data_src.dart
  String getRemoteDataSrcPath(String featureName) {
    return path.join(
      getFeatureRoot(featureName.snakeCase),
      'data',
      'datasources',
      '${featureName.snakeCase}_remote_data_src.dart',
    );
  }

  /// Get the repository implementation file path
  /// e.g., lib/features/auth/data/repositories/auth_repository_impl.dart
  String getRepoImplPath(String featureName) {
    return path.join(
      getFeatureRoot(featureName.snakeCase),
      'data',
      'repositories',
      '${featureName.snakeCase}_repository_impl.dart',
    );
  }

  /// Get the test file path for repository implementation
  /// e.g., test/features/auth/data/repositories/auth_repository_impl_test.dart
  String getRepoImplTestPath(String featureName) {
    return path.join(
      'test',
      config.featureScaffolding.rootName,
      featureName.snakeCase,
      'data',
      'repositories',
      '${featureName.snakeCase}_repository_impl_test.dart',
    );
  }

  /// Get the interface adapter directory path
  /// e.g., lib/features/auth/presentation/adapters/
  String getInterfaceAdapterDirPath(String featureName) {
    return path.join(
      getFeatureRoot(featureName.snakeCase),
      'presentation',
      'adapters',
    );
  }

  /// Get the interface adapter file path
  ///
  /// e.g., lib/features/auth/presentation/adapters/auth_adapter.dart
  String getInterfaceAdapterPath(String featureName) {
    return path.join(
      getInterfaceAdapterDirPath(featureName.snakeCase),
      '${featureName.snakeCase}_adapter.dart',
    );
  }

  /// Get the interface adapter state file path
  ///
  /// e.g., lib/features/auth/presentation/adapters/auth_state.dart
  String getInterfaceAdapterStatePath(String featureName) {
    return path.join(
      getInterfaceAdapterDirPath(featureName.snakeCase),
      '${featureName.snakeCase}_state.dart',
    );
  }

  /// Get the usecases test directory path
  /// e.g., test/features/auth/domain/usecases/
  String getUsecasesTestDirPath(String featureName) {
    return path.join(
      'test',
      config.featureScaffolding.rootName,
      featureName.snakeCase,
      'domain',
      'usecases',
    );
  }

  /// Get the usecases mock file path
  String getUsecasesRepoMockPath(String featureName) {
    return path.join(
      getUsecasesTestDirPath(featureName),
      '${featureName.snakeCase}.mock.dart',
    );
  }

  /// Get the test file path for a usecase
  /// e.g., test/features/auth/domain/usecases/register_test.dart
  String getUsecaseTestPath({
    required String featureName,
    required String methodName,
  }) {
    return path.join(
      'test',
      config.featureScaffolding.rootName,
      featureName.snakeCase,
      'domain',
      'usecases',
      '${methodName.snakeCase}_test.dart',
    );
  }

  /// Get the entity file path
  ///
  /// e.g., lib/features/auth/domain/entities/user.dart
  String getEntityPath({
    required String featureName,
    required String entityName,
  }) {
    return path.join(
      getFeatureRoot(featureName.snakeCase),
      'domain',
      'entities',
      '${entityName.snakeCase}.dart',
    );
  }

  /// Get the model file path
  ///
  /// e.g., lib/features/auth/data/models/user_model.dart
  String getModelPath({
    required String featureName,
    required String entityName,
  }) {
    return path.join(
      getFeatureRoot(featureName.snakeCase),
      'data',
      'models',
      '${entityName.snakeCase}_model.dart',
    );
  }

  /// Get the model test file path
  ///
  /// e.g., test/features/auth/data/models/user_model_test.dart
  String getModelTestPath({
    required String featureName,
    required String entityName,
  }) {
    return path.join(
      'test',
      config.featureScaffolding.rootName,
      featureName.snakeCase,
      'data',
      'models',
      '${entityName.snakeCase}_model_test.dart',
    );
  }

  /// Get the fixture file path
  ///
  /// e.g., test/fixtures/user.json
  String getModelFixturePath({required String entityName}) {
    return path.join(
      'test',
      'fixtures',
      '${entityName.snakeCase}.json',
    );
  }

  /// Get the fixture reader file path
  String getFixtureReaderPath() {
    return path.join(
      'test',
      'fixtures',
      'fixture_reader.dart',
    );
  }

  /// Check if a file exists
  bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  /// Check if the fixture reader file exists
  bool fixtureReaderExists() {
    return fileExists(getFixtureReaderPath());
  }

  /// Create a file with its parent directories
  void createFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
  }

  /// Write content to a file, optionally creating it if it doesn't exist
  void writeToFile(
    String filePath,
    String content, {
    bool createIfMissing = true,
  }) {
    final file = File(filePath);

    if (!file.existsSync()) {
      if (createIfMissing && shouldAutoCreate) {
        file.createSync(recursive: true);
      } else {
        throw Exception(
          'File $filePath does not exist and auto-creation is disabled',
        );
      }
    }

    file.writeAsStringSync(content);
  }

  /// Merge generated content into an existing file
  /// This preserves user-written code while updating generated sections
  Future<void> mergeIntoFile(
    String filePath,
    String generatedContent, {
    String startMarker = '// GENERATED CODE - DO NOT MODIFY BY HAND',
    String endMarker = '// END GENERATED CODE',
  }) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      if (shouldAutoCreate) {
        // Create new file with generated content
        writeToFile(filePath, generatedContent);
        return;
      } else {
        throw Exception(
          'File $filePath does not exist and auto-creation is disabled',
        );
      }
    }

    final existingContent = await file.readAsString();

    // Check if there's already a generated section
    final startIndex = existingContent.indexOf(startMarker);
    final endIndex = existingContent.indexOf(endMarker);

    String newContent;
    if (startIndex != -1 && endIndex != -1) {
      // Replace existing generated section
      newContent =
          existingContent.substring(0, startIndex) +
          generatedContent +
          existingContent.substring(endIndex + endMarker.length);
    } else {
      // Append generated content
      newContent = '$existingContent\n\n$generatedContent';
    }

    await file.writeAsString(newContent);
  }

  /// Resolve generated code with DartEmitter and DartFormatter
  String resolveGeneratedCode({
    required Library library,
    DartEmitter? emitter,
  }) {
    final libEmitter =
        emitter ??
        DartEmitter(
          useNullSafetySyntax: true,
          orderDirectives: true,
        );
    return DartFormatter().format('${library.accept(libEmitter)}');
  }

  /// Get standard imports for a repository file
  List<String> getRepositoryImports(String featureName) {
    return [
      'package:${config.appName}/core/typedefs.dart',
    ];
  }

  /// Get standard imports for a usecase file
  List<String> getUsecaseImports(
    String featureName,
    String methodName, {
    bool hasCustomParams = false,
  }) {
    final imports = <String>[
      'package:${config.appName}/core/usecases/usecase.dart',
      'package:${config.appName}/core/typedefs.dart',
      '${getFeaturePackagePath(featureName)}/domain/repositories/${featureName}_repository.dart',
    ];

    if (hasCustomParams) {
      imports.add('package:equatable/equatable.dart');
    }

    return imports;
  }

  /// Get repository import statement for a usecase file
  String getRepositoryImportStatement({
    required String featureName,
  }) {
    final rootName = config.featureScaffolding.rootName;
    return 'package:${config.appName}/$rootName/${featureName.snakeCase}/domain/repositories/${featureName.snakeCase}_repository.dart';
  }

  /// Get usecase import statement for a file
  String getUsecaseImportStatement({
    required String featureName,
    required String methodName,
  }) {
    return '${getFeaturePackagePath(featureName.snakeCase)}/domain/usecases/${methodName.snakeCase}.dart';
  }

  /// Get standard imports for a remote data source file
  List<String> getRemoteDataSrcImports({required String featureName}) {
    return config.remoteDataSourceConfig.requiredImports.map((i) => i).toList();
  }

  /// Get standard imports for a repository implementation file
  ///
  /// The [hasStream] parameter determines whether to include 'dart:async'
  /// for Stream-based return types since the repoImpl uses a
  /// `StreamTransformer` on them
  List<String> getRepoImplImports({
    required String featureName,
    required bool hasStream,
  }) {
    return [
      'package:${config.appName}/core/errors/exceptions.dart',
      'package:${config.appName}/core/errors/failures.dart',
      'package:${config.appName}/core/typedefs.dart',
      'package:dartz/dartz.dart',
      if (hasStream) 'dart:async',
      '${getFeaturePackagePath(featureName.snakeCase)}/domain/repositories/${featureName.snakeCase}_repository.dart',
      '${getFeaturePackagePath(featureName.snakeCase)}/data/datasources/${featureName.snakeCase}_remote_data_src.dart',
    ];
  }

  /// Get standard imports for a repository test file
  List<String> getRepoTestImports({required String featureName}) {
    return [
      'package:flutter_test/flutter_test.dart',
      'package:mocktail/mocktail.dart',
      'package:dartz/dartz.dart',
      'package:${config.appName}/core/errors/exceptions.dart',
      'package:${config.appName}/core/errors/failures.dart',
      'package:${config.appName}/core/typedefs.dart',
      '${getFeaturePackagePath(featureName.snakeCase)}/data/datasources/${featureName.snakeCase}_remote_data_source.dart',
      '${getFeaturePackagePath(featureName.snakeCase)}/data/repositories/${featureName.snakeCase}_repository_impl.dart',
    ];
  }

  /// Get standard imports for a usecase test file
  List<String> getUsecaseTestImports({
    required String repoName,
    required String featureName,
    required String methodName,
  }) {
    return [
      'package:dartz/dartz.dart',
      'package:flutter_test/flutter_test.dart',
      'package:mocktail/mocktail.dart',
      'package:${config.appName}/core/errors/failures.dart',
      getUsecaseImportStatement(
        featureName: featureName,
        methodName: methodName,
      ),
      '${repoName.snakeCase}.mock.dart',
    ];
  }

  /// Get standard imports for an interface adapter file (e.g., a BLoC).
  ///
  /// This includes imports for `bloc`, `equatable`, and all the generated
  /// usecase files corresponding to the repository [methods].
  List<String> getInterfaceAdapterImports({
    required List<IFunction> methods,
    required String featureName,
  }) {
    var hasStream = false;
    final imports = [
      'package:bloc/bloc.dart',
      'package:equatable/equatable.dart',
      ...methods.map((method) {
        if (!hasStream && method.rawType.isDartAsyncStream) hasStream = true;
        final usecaseFile = method.name.snakeCase;
        final packagePath = getFeaturePackagePath(featureName.snakeCase);
        return '$packagePath/domain/usecases/$usecaseFile.dart';
      }),
    ];
    if (hasStream) {
      imports.addAll([
        'dart:async',
        'package:dartz/dartz.dart',
        'package:${config.appName}/core/errors/failures.dart',
      ]);
    }
    return imports;
  }

  /// Get standard imports for a domain entity file
  List<String> getDomainEntityImports() {
    return ['package:equatable/equatable.dart'];
  }

  /// Get standard imports for a model file
  List<String> getModelImports() {
    return ['package:${config.appName}/core/typedefs.dart', 'dart:convert'];
  }

  /// Get standard imports for a model test file
  List<String> getModelTestImports({
    required String entityName,
    required String featureName,
  }) {
    return [
      'package:flutter_test/flutter_test.dart',
      'dart:convert',
      'package:${config.appName}/core/typedefs.dart',
      '../../../fixtures/fixture_reader.dart',
      '${getFeaturePackagePath(featureName.snakeCase)}/data/models/${entityName.snakeCase}_model.dart',
      '${getFeaturePackagePath(featureName.snakeCase)}/domain/entities/${entityName.snakeCase}.dart',
    ];
  }

  /// Generates import statements for a set of entities by checking
  /// their existence
  /// in the file system (Current Feature -> Self Feature -> Core -> Common).
  ImportResult getSmartEntityImports({
    required Set<String> entities,
    required String currentFeature,
    bool isModel = false,
  }) {
    if (entities.isEmpty) return (imports: [], importComments: []);

    final imports = <String>[];
    final importComments = <String>[];
    final currentFeatureSnake = currentFeature.snakeCase;
    final rootName = config.featureScaffolding.rootName;

    final layer = isModel ? 'data/models' : 'domain/entities';

    for (final entity in entities) {
      final entitySnake = entity.snakeCase + (isModel ? '_model' : '');
      var found = false;

      // DEFINE PATHS
      final pathsToCheck = [
        // 1. Current Feature Domain (Most likely)
        '$rootName/$currentFeatureSnake/$layer/$entitySnake.dart',
        // 2. Self-named Feature (e.g. features/user/domain/entities/user.dart)
        '$rootName/$entitySnake/$layer/$entitySnake.dart',
        // 3. Core (Shared entities)
        'core/${isModel ? 'models' : 'entities'}/$entitySnake.dart',
        // 4. Common (Shared entities)
        'common/${isModel ? 'models' : 'entities'}/$entitySnake.dart',
        // 4. Common (Shared entities)
        'core/common/${isModel ? 'models' : 'entities'}/$entitySnake.dart',
      ];

      for (final relativePath in pathsToCheck) {
        // We check strict file existence
        if (fileExists('lib/$relativePath')) {
          imports.add('package:${config.appName}/$relativePath');
          found = true;
          break; // Stop looking once found
        }
      }

      if (!found) {
        final featureConfig =
            config.featureScaffolding.features[currentFeature.snakeCase];
        // this works even for models because the `entities` list is coming
        // from the ModelVisitor, which scans the annotated class, and the
        // annotated class is always an entity, therefore, its composite
        // entities are also going to be pure entities, never models.
        //
        // For this reason, I do not have to worry about a "model" suffix in
        // the condition that uses "entity.snakeCase".
        if (featureConfig != null &&
            featureConfig.entities.contains(entity.snakeCase)) {
          final relativePath =
              '$rootName/$currentFeatureSnake/$layer/$entitySnake.dart';
          imports.add('package:${config.appName}/$relativePath');

          continue;
        }
        // Fallback: If we identified it as a candidate but couldn't find
        // the file,
        // it might be in a weird location. We comment it out so the
        // dev notices.
        importComments.add(
          '// import ${getFeaturePackagePath(currentFeatureSnake)}/$layer'
          "/$entitySnake.dart'; // Warning: Could not locate "
          'file for $entity',
        );
      }
    }
    return (imports: imports, importComments: importComments);
  }

  /// Generate smart imports for a repository implementation test file
  ImportResult generateSmartRepoImplTestImports({
    required String featureName,
    required Set<String> candidates,
  }) {
    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      standardImports: getRepoTestImports(featureName: featureName),
    );
  }

  /// Generate smart imports for a repository implementation file
  ///
  /// The [hasStream] parameter determines whether to include 'dart:async'
  /// for Stream-based return types since the repoImpl uses a
  /// `StreamTransformer` on them
  ImportResult generateSmartRepoImplImports({
    required Set<String> candidates,
    required String featureName,
    required bool hasStream,
  }) {
    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      standardImports: getRepoImplImports(
        featureName: featureName.snakeCase,
        hasStream: hasStream,
      ),
    );
  }

  /// Generate smart imports for any layer that needs smart entity imports.
  ImportResult _generateSmartImports({
    required Set<String> candidates,
    required String currentFeatureSnake,
    bool customTypeIsModel = false,
    List<String>? standardImports,
  }) {
    final imports = List<String>.from(standardImports ?? []);
    var importComments = <String>[];

    // Dynamic Entity Imports
    if (candidates.isNotEmpty) {
      final entityImports = getSmartEntityImports(
        entities: candidates,
        currentFeature: currentFeatureSnake,
        isModel: customTypeIsModel,
      );
      imports.addAll(entityImports.imports);
      importComments = entityImports.importComments;
    }
    return (imports: imports, importComments: importComments);
  }

  /// Generate smart imports for a usecase file
  ImportResult generateSmartRemoteDataSrcImports({
    required Set<String> candidates,
    required String featureName,
  }) {
    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      customTypeIsModel: true,
      standardImports: getRemoteDataSrcImports(
        featureName: featureName.snakeCase,
      ),
    );
  }

  /// Generate smart imports for a usecase file
  ImportResult generateSmartUsecaseImports({
    required Set<String> candidates,
    required String featureName,
    required String methodName,
    bool hasCustomParams = false,
  }) {
    final standardImports = getUsecaseImports(
      featureName.snakeCase,
      methodName,
      hasCustomParams: hasCustomParams,
    );

    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      standardImports: standardImports,
    );
  }

  /// Generate smart imports for a repository file
  ImportResult generateSmartRepoImports({
    required Set<String> candidates,
    required String featureName,
  }) {
    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      standardImports: getRepositoryImports(featureName.snakeCase),
    );
  }

  /// Generate smart imports for an interface adapter file
  ImportResult generateSmartInterfaceAdapterImports({
    required Set<String> candidates,
    required List<IFunction> methods,
    required String featureName,
  }) {
    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      standardImports: getInterfaceAdapterImports(
        methods: methods,
        featureName: featureName.snakeCase,
      ),
    );
  }

  /// Generate smart imports for an entity file
  ImportResult generateSmartDomainEntityImports({
    required Set<String> candidates,
    required String featureName,
  }) {
    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      standardImports: getDomainEntityImports(),
    );
  }

  /// Generate smart imports for a model file
  ImportResult generateSmartModelImports({
    required Set<String> candidates,
    required String featureName,
    required String parentEntityName,
  }) {
    final (:imports, :importComments) = _generateSmartImports(
      candidates: candidates,
      currentFeatureSnake: featureName.snakeCase,
      standardImports: getModelImports(),
      customTypeIsModel: true,
    );

    final parentEntityImport = _generateSmartImports(
      candidates: {parentEntityName},
      currentFeatureSnake: featureName.snakeCase,
    );

    return (
      imports: imports..addAll(parentEntityImport.imports),
      importComments: importComments..addAll(parentEntityImport.importComments),
    );
  }

  /// Generate smart imports for a usecase test file
  ImportResult generateSmartUsecaseTestImports({
    required Set<String> candidates,
    required String featureName,
    required String methodName,
    required String repoName,
  }) {
    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      standardImports: getUsecaseTestImports(
        featureName: featureName.snakeCase,
        methodName: methodName,
        repoName: repoName,
      ),
    );
  }

  /// Generate smart imports for a model test file
  ImportResult generateSmartModelTestImports({
    required Set<String> candidates,
    required String featureName,
    required String entityName,
  }) {
    return _generateSmartImports(
      currentFeatureSnake: featureName.snakeCase,
      candidates: candidates,
      standardImports: getModelTestImports(
        featureName: featureName.snakeCase,
        entityName: entityName.snakeCase,
      ),
      customTypeIsModel: true,
    );
  }
}

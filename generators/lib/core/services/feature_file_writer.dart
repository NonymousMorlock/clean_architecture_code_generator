// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:path/path.dart' as path;

/// Service for resolving and writing generated code to feature files
/// instead of .g.dart files when multi-file output is enabled.
class FeatureFileWriter {
  /// Creates a [FeatureFileWriter] with the given configuration and build step.
  FeatureFileWriter(this.config, this.buildStep);

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
  String? extractFeatureName() {
    final inputPath = buildStep.inputId.path;
    final parts = inputPath.split('/');

    // Look for 'features' in the path
    final featuresIndex = parts.indexOf('features');
    if (featuresIndex != -1 && featuresIndex + 1 < parts.length) {
      return parts[featuresIndex + 1];
    }

    return null;
  }

  /// Extract the base name from a repository class name
  /// e.g., AuthRepoTBG -> auth, UserRepoTBG -> user
  String extractBaseName(String repoClassName) {
    return repoClassName
        .replaceAll('RepoTBG', '')
        .replaceAll('Repo', '')
        .snakeCase;
  }

  /// Get the feature root directory path
  /// e.g., lib/features/auth
  String getFeatureRoot(String featureName) {
    return path.join(config.outputPath, 'features', featureName);
  }

  /// Get the domain repository file path
  /// e.g., lib/features/auth/domain/repositories/auth_repository.dart
  String getDomainRepoPath(String featureName, String baseName) {
    return path.join(
      getFeatureRoot(featureName),
      'domain',
      'repositories',
      '${baseName}_repository.dart',
    );
  }

  /// Get the usecase file path for a specific method
  /// e.g., lib/features/auth/domain/usecases/register.dart
  String getUsecasePath(String featureName, String methodName) {
    return path.join(
      getFeatureRoot(featureName),
      'domain',
      'usecases',
      '${methodName.snakeCase}.dart',
    );
  }

  /// Get the remote data source file path
  /// e.g., lib/features/auth/data/datasources/auth_remote_data_src.dart
  String getRemoteDataSrcPath(String featureName, String baseName) {
    return path.join(
      getFeatureRoot(featureName),
      'data',
      'datasources',
      '${baseName}_remote_data_src.dart',
    );
  }

  /// Get the repository implementation file path
  /// e.g., lib/features/auth/data/repositories/auth_repository_impl.dart
  String getRepoImplPath(String featureName, String baseName) {
    return path.join(
      getFeatureRoot(featureName),
      'data',
      'repositories',
      '${baseName}_repository_impl.dart',
    );
  }

  /// Get the test file path for repository implementation
  /// e.g., test/features/auth/data/repositories/auth_repository_impl_test.dart
  String getRepoImplTestPath(String featureName, String baseName) {
    return path.join(
      'test',
      'features',
      featureName,
      'data',
      'repositories',
      '${baseName}_repository_impl_test.dart',
    );
  }

  /// Get the test file path for a usecase
  /// e.g., test/features/auth/domain/usecases/register_test.dart
  String getUsecaseTestPath(String featureName, String methodName) {
    return path.join(
      'test',
      'features',
      featureName,
      'domain',
      'usecases',
      '${methodName.snakeCase}_test.dart',
    );
  }

  /// Check if a file exists
  bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  /// Create a file with its parent directories
  void createFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
  }

  /// Write content to a file, optionally creating it if it doesn't exist
  Future<void> writeToFile(
    String filePath,
    String content, {
    bool createIfMissing = true,
  }) async {
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

    await file.writeAsString(content);
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
        await writeToFile(filePath, generatedContent);
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

  /// Generate a complete file with imports and generated code
  String generateCompleteFile({
    required String generatedCode,
    List<String>? imports,
    String? header,
  }) {
    final buffer = StringBuffer();

    // Add header comment
    if (header != null) {
      buffer
        ..writeln(header)
        ..writeln();
    }

    // Add imports
    imports?.forEach(buffer.writeln);

    if (imports?.isNotEmpty ?? false) {
      buffer.writeln();
    }

    // Add generated code
    buffer.write(generatedCode);

    return buffer.toString();
  }

  /// Get standard imports for a repository file
  List<String> getRepositoryImports(String featureName, String baseName) {
    return [
      "import 'package:${config.appName}/core/typedefs.dart';",
      "import '../entities/$baseName.dart';",
    ];
  }

  /// Get standard imports for a usecase file
  List<String> getUsecaseImports(
    String featureName,
    String baseName,
    String methodName, {
    bool hasParams = false,
    bool isStream = false,
  }) {
    final imports = <String>[
      "import 'package:${config.appName}/core/usecases/usecase.dart';",
      "import 'package:${config.appName}/core/typedefs.dart';",
      "import '../repositories/${baseName}_repository.dart';",
    ];

    if (hasParams) {
      imports.add("import 'package:equatable/equatable.dart';");
    }

    return imports;
  }

  /// Get standard imports for a remote data source file
  List<String> getRemoteDataSrcImports(String featureName, String baseName) {
    final imports = <String>[
      // Add HTTP client imports based on config
      ...config.remoteDataSourceConfig.requiredImports.map(
        (i) => "import '$i';",
      ),
      // Add model import
      "import '../models/${baseName}_model.dart';",
    ];

    return imports;
  }

  /// Get standard imports for a repository implementation file
  List<String> getRepoImplImports(String featureName, String baseName) {
    return [
      "import 'package:${config.appName}/core/errors/exceptions.dart';",
      "import 'package:${config.appName}/core/errors/failures.dart';",
      "import 'package:${config.appName}/core/typedefs.dart';",
      "import 'package:dartz/dartz.dart';",
      "import '../../domain/repositories/${baseName}_repository.dart';",
      "import '../datasources/${baseName}_remote_data_src.dart';",
    ];
  }

  /// Get standard imports for a test file
  List<String> getRepoTestImports({
    required String featureName,
    required String baseName,
  }) {
    return [
      "import 'package:flutter_test/flutter_test.dart';",
      "import 'package:mocktail/mocktail.dart';",
      "import 'package:dartz/dartz.dart';",
      "import 'package:${config.appName}/core/errors/exceptions.dart';",
      "import 'package:${config.appName}/core/errors/failures.dart';",
      "import 'package:${config.appName}/core/typedefs.dart';",
    ];
  }

  /// Generates import statements for a set of entities by checking
  /// their existence
  /// in the file system (Current Feature -> Self Feature -> Core -> Common).
  List<String> getSmartEntityImports({
    required Set<String> entities,
    required String currentFeature,
  }) {
    if (entities.isEmpty) return [];

    final imports = <String>[];
    final currentFeatureSnake = currentFeature.snakeCase;

    for (final entity in entities) {
      final entitySnake = entity.snakeCase;
      var found = false;

      // DEFINE PATHS
      final pathsToCheck = [
        // 1. Current Feature Domain (Most likely)
        'features/$currentFeatureSnake/domain/entities/$entitySnake.dart',
        // 2. Self-named Feature (e.g. features/user/domain/entities/user.dart)
        'features/$entitySnake/domain/entities/$entitySnake.dart',
        // 3. Core (Shared entities)
        'core/entities/$entitySnake.dart',
        // 4. Common (Shared entities)
        'common/entities/$entitySnake.dart',
      ];

      for (final relativePath in pathsToCheck) {
        // We check strict file existence
        if (fileExists('lib/$relativePath')) {
          imports.add("import 'package:${config.appName}/$relativePath';");
          found = true;
          break; // Stop looking once found
        }
      }

      if (!found) {
        // Fallback: If we identified it as a candidate but couldn't find
        // the file,
        // it might be in a weird location. We comment it out so the
        // dev notices.
        imports.add(
          "// import '.../domain/entities/$entitySnake.dart'; // Warning: Could not locate file for $entity",
        );
      }
    }
    return imports;
  }

  /// Generate smart imports for a repository implementation test file
  List<String> generateSmartRepoImplTestImports(
    String currentFeatureSnake,
    String repoName,
    String repoImplName,
    String remoteDataSourceName,
    Set<String> candidates,
  ) {
    final appName = config.appName;

    final imports = [
      // Standard Imports
      ...getRepoTestImports(
        featureName: currentFeatureSnake,
        baseName: repoName,
      ),
      // Current Feature Data Layer Imports
      "import 'package:$appName/features/$currentFeatureSnake/data/datasources/${currentFeatureSnake}_remote_data_source.dart';",
      "import 'package:$appName/features/$currentFeatureSnake/data/models/${currentFeatureSnake}_model.dart';",
      "import 'package:$appName/features/$currentFeatureSnake/data/repositories/${currentFeatureSnake}_repository_impl.dart';",
    ];

    // Dynamic Entity Imports
    if (candidates.isNotEmpty) {
      imports.addAll(
        getSmartEntityImports(
          entities: candidates,
          currentFeature: currentFeatureSnake,
        ),
      );
    }
    return imports;
  }
}

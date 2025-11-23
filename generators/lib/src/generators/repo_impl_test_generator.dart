// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating test files for repository implementations.
///
/// Processes classes annotated with `@RepoImplTestGenAnnotation` and generates
/// comprehensive test files for repository implementation classes.
class RepoImplTestGenerator
    extends GeneratorForAnnotation<RepoImplTestGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    // Load config to check if multi-file output is enabled
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final writer = FeatureFileWriter(config, buildStep);

    if (writer.isMultiFileEnabled) {
      return _generateMultiFile(visitor, writer, buildStep);
    }

    // Default behavior: generate to .g.dart
    final buffer = StringBuffer();
    _generateRepoImplTest(buffer, visitor);
    return buffer.toString();
  }

  String _generateMultiFile(
    RepoVisitor visitor,
    FeatureFileWriter writer,
    BuildStep buildStep,
  ) {
    final featureName = writer.extractFeatureName();
    if (featureName == null) {
      // Fallback to default
      final buffer = StringBuffer();
      _generateRepoImplTest(buffer, visitor);
      return buffer.toString();
    }

    final baseName = writer.extractBaseName(visitor.className);
    final testPath = writer.getRepoImplTestPath(featureName, baseName);

    // Generate test code
    final buffer = StringBuffer();
    _generateRepoImplTest(buffer, visitor);

    // Generate complete file with imports (imports are already
    // in the generated code)
    final completeFile = '// GENERATED CODE - DO NOT MODIFY BY HAND\n\n$buffer';

    // Write to the test file
    try {
      File(testPath).writeAsStringSync(completeFile);
    } on PathNotFoundException catch (e) {
      if (writer.shouldAutoCreate) {
        // Create the file and write
        File(testPath)
          ..createSync(recursive: true)
          ..writeAsStringSync(completeFile);
        stdout.writeln('Info: Created missing file at $testPath');
      } else {
        stderr.writeln(
          'Warning: Path not found for $testPath. '
          'Ensure the target file exists or enable auto-creation. $e',
        );
      }
    } on Exception catch (e) {
      stderr.writeln('Warning: Could not write to $testPath: $e');
    }

    // Return a minimal marker for the .g.dart file
    return '// Repository implementation test written to: $testPath\n';
  }

  void _generateRepoImplTest(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    final repoName = className.replaceAll('TBG', '');
    final repoImplName = '${repoName}Impl';
    final remoteDataSourceName =
        '${className.substring(0, className.length - 4)}RemoteDataSource';
    final mockDataSourceName = 'Mock$remoteDataSourceName';

    final currentFeatureName = className
        .replaceAll('RepoTBG', '')
        .replaceAll('Repo', '')
        .snakeCase;

    final usedEntities = _discoverRequiredEntities(visitor);

    // Generate Imports (Dynamic based on discovery)
    _generateSmartImports(
      buffer,
      currentFeatureName,
      repoName,
      repoImplName,
      remoteDataSourceName,
      usedEntities,
    );

    // Generate mock class
    buffer
      ..writeln(
        'class $mockDataSourceName extends Mock '
        'implements $remoteDataSourceName {}',
      )
      ..writeln()
      // Generate main test function
      ..writeln('void main() {')
      ..writeln('  late $mockDataSourceName remoteDataSource;')
      ..writeln('  late $repoImplName repoImpl;')
      ..writeln();

    // Register Fallbacks for discovered entities
    _generateFallbackRegistration(buffer, usedEntities);

    buffer
      ..writeln('  setUp(() {')
      ..writeln('    remoteDataSource = $mockDataSourceName();')
      ..writeln('    repoImpl = $repoImplName(remoteDataSource);')
      ..writeln('  });')
      ..writeln();

    // Generate tests for each method
    for (final method in visitor.methods) {
      _generateMethodTest(
        buffer,
        method,
        currentFeatureName,
        remoteDataSourceName,
      );
    }

    buffer.writeln('}');
  }

  /// Scans all methods to find strict Entity dependencies
  Set<String> _discoverRequiredEntities(RepoVisitor visitor) {
    final entities = <String>{};

    void scanType(String typeString) {
      // 1. Break down complex types (Future<Either<Failure,
      // List<User>>> -> {User})
      final allTypes = typeString.allConstituentTypes;

      // 2. Filter for actual Entities
      for (final type in allTypes) {
        if (type.isPotentialEntity) {
          entities.add(type);
        }
      }
    }

    for (final method in visitor.methods) {
      // Scan Return Type
      scanType(method.returnType);

      // Scan Parameters
      if (method.params != null) {
        for (final param in method.params!) {
          scanType(param.type);
        }
      }
    }
    return entities;
  }

  void _generateSmartImports(
    StringBuffer buffer,
    String currentFeatureSnake,
    String repoName,
    String repoImplName,
    String remoteDataSourceName,
    Set<String> entities,
  ) {
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final appName = config.appName;

    // Standard Imports
    buffer
      ..writeln("import 'package:dartz/dartz.dart';")
      ..writeln("import 'package:flutter_test/flutter_test.dart';")
      ..writeln("import 'package:mocktail/mocktail.dart';")
      ..writeln()
      ..writeln("import 'package:$appName/core/errors/exceptions.dart';")
      ..writeln("import 'package:$appName/core/errors/failures.dart';")
      ..writeln("import 'package:$appName/core/typedefs.dart';")
      ..writeln()
      // Current Feature Data Layer
      ..writeln(
        "import 'package:$appName/features/$currentFeatureSnake/data/datasources/${currentFeatureSnake}_remote_data_source.dart';",
      )
      ..writeln(
        "import 'package:$appName/features/$currentFeatureSnake/data/models/${currentFeatureSnake}_model.dart';",
      )
      ..writeln(
        "import 'package:$appName/features/$currentFeatureSnake/data/repositories/${currentFeatureSnake}_repository_impl.dart';",
      );

    // Dynamic Entity Imports
    if (entities.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('// Entity Imports');

      for (final entity in entities) {
        final entitySnake = entity.snakeCase;

        // LOGIC: Where does this entity live?

        // Path 1: Is it in the current feature?
        // lib/features/auth/domain/entities/user.dart
        final currentFeaturePath =
            'features/$currentFeatureSnake/domain/entities/$entitySnake.dart';

        // Path 2: Is it in a feature named after itself?
        // (Common convention: User entity in User feature)
        // lib/features/user/domain/entities/user.dart
        final selfFeaturePath =
            'features/$entitySnake/domain/entities/$entitySnake.dart';

        // Path 3: Is it in core?
        // lib/core/entities/user.dart
        final corePath = 'core/entities/$entitySnake.dart';

        final modelPath =
            'features/$currentFeatureSnake/data/models/${entity.snakeCase}_model.dart';
        if (_fileExists('lib/$modelPath')) {
          buffer.writeln("import 'package:$appName/$modelPath';");
        }

        // We use a heuristic here because we are generating code string.
        // Ideally, we check file existence using basic File I/O relative to project root.

        if (_fileExists('lib/$currentFeaturePath')) {
          buffer.writeln("import 'package:$appName/$currentFeaturePath';");
        } else if (_fileExists('lib/$selfFeaturePath')) {
          buffer.writeln("import 'package:$appName/$selfFeaturePath';");
        } else if (_fileExists('lib/$corePath')) {
          buffer.writeln("import 'package:$appName/$corePath';");
        } else {
          // Fallback: Assume it's in the current feature to prevent
          // breaking compilation
          // entirely, or add a TODO comment.
          buffer.writeln(
            "import 'package:$appName/$currentFeaturePath'; // Warning: File check failed",
          );
        }
      }
    }
    buffer.writeln();
  }

  void _generateFallbackRegistration(
    StringBuffer buffer,
    Set<String> entities,
  ) {
    if (entities.isEmpty) return;

    // Create instances
    for (final entity in entities) {
      buffer.writeln('  final t$entity = $entity.empty();');
    }

    buffer
      ..writeln()
      ..writeln('  setUpAll(() {');

    for (final entity in entities) {
      buffer.writeln('    registerFallbackValue(t$entity);');
    }

    buffer
      ..writeln('  });')
      ..writeln();
  }

  /// Helper to check file existence relative to project root
  bool _fileExists(String relativePath) {
    return File(relativePath).existsSync();
  }

  void _generateMethodTest(
    StringBuffer buffer,
    IFunction method,
    String featureName,
    String remoteDataSourceName,
  ) {
    final methodName = method.name;
    final returnType = method.returnType.rightType;
    final isStream = method.returnType.startsWith('Stream');
    final isVoid = returnType.toLowerCase().trim() == 'void';

    buffer.writeln("  group('$methodName', () {");

    // Generate test data
    _generateTestData(buffer, method, returnType, featureName);

    // Generate success test
    _generateSuccessTest(
      buffer,
      method,
      returnType,
      isStream,
      isVoid,
      featureName,
    );

    // Generate failure test
    _generateFailureTest(buffer, method, returnType, isStream, isVoid);

    buffer
      ..writeln('  });')
      ..writeln();
  }

  void _generateTestData(
    StringBuffer buffer,
    IFunction method,
    String returnType,
    String featureName,
  ) {
    if (returnType.toLowerCase().startsWith('list')) {
      final innerType = returnType.substring(5, returnType.length - 1);
      final modelType = '${innerType}Model';
      buffer
        ..writeln('    final expected${innerType}s = [')
        ..writeln('      $modelType.empty(),')
        ..writeln("      $modelType.empty().copyWith(id: '1'),")
        ..writeln('    ];');
    } else if (!returnType.toLowerCase().trim().contains('void')) {
      final modelType = '${returnType}Model';
      buffer.writeln('    final expected$returnType = $modelType.empty();');
    }

    // Generate parameter constants
    if (method.params != null) {
      for (final param in method.params!) {
        if (param.type.toLowerCase() == 'string') {
          buffer.writeln(
            "    const ${param.name} = 'sample${param.name.upperCamelCase}';",
          );
        } else if (param.type.toLowerCase() == 'int') {
          buffer.writeln('    const ${param.name} = 1;');
        } else if (param.type.toLowerCase() == 'bool') {
          buffer.writeln('    const ${param.name} = true;');
        }
      }
    }

    buffer
      ..writeln()
      ..writeln('    const serverFailure = ServerFailure(')
      ..writeln("      message: 'Server error',")
      ..writeln("      statusCode: '500',")
      ..writeln('    );')
      ..writeln();
  }

  void _generateSuccessTest(
    StringBuffer buffer,
    IFunction method,
    String returnType,
    bool isStream,
    bool isVoid,
    String featureName,
  ) {
    final methodName = method.name;
    final namedParams =
        method.params
            ?.where((p) => p.isNamed)
            .map((p) => '${p.name}: ${p.name}')
            .join(', ') ??
        '';
    final positionalParams =
        method.params?.where((p) => !p.isNamed).map((p) => p.name).join(', ') ??
        '';

    final callParams = method.params != null
        ? (namedParams.isNotEmpty && positionalParams.isNotEmpty)
              ? '$positionalParams, $namedParams'
              : namedParams.isNotEmpty
              ? namedParams
              : positionalParams
        : '';

    if (isStream) {
      buffer
        ..writeln('    test(')
        ..writeln(
          "      'should return a stream of Right<$returnType> "
          "when remote data source '",
        )
        ..writeln("      'is successful',")
        ..writeln('      () {');

      // Mock setup
      if (method.params != null) {
        final mockParams = method.params!
            .map((p) => 'any(${p.isNamed ? "named: '${p.name}'" : ''})')
            .join(', ');
        buffer.writeln(
          '        when(() => '
          'remoteDataSource.$methodName($mockParams)).thenAnswer(',
        );
      } else {
        buffer.writeln(
          '        when(() => remoteDataSource.$methodName()).thenAnswer(',
        );
      }

      if (returnType.toLowerCase().startsWith('list')) {
        final innerType = returnType.substring(5, returnType.length - 1);
        buffer.writeln('          (_) => Stream.value(expected${innerType}s),');
      } else {
        buffer.writeln('          (_) => Stream.value(expected$returnType),');
      }
      buffer
        ..writeln('        );')
        ..writeln();

      // Test execution
      if (callParams.isNotEmpty) {
        buffer.writeln(
          '        final stream = repoImpl.$methodName($callParams);',
        );
      } else {
        buffer.writeln('        final stream = repoImpl.$methodName();');
      }
      buffer.writeln();

      // Expectation
      if (returnType.toLowerCase().startsWith('list')) {
        final innerType = returnType.substring(5, returnType.length - 1);
        buffer
          ..writeln('        expect(')
          ..writeln('          stream,')
          ..writeln(
            '          emits(Right<Failure, '
            '$returnType>(expected${innerType}s)),',
          )
          ..writeln('        );');
      } else {
        buffer
          ..writeln('        expect(')
          ..writeln('          stream,')
          ..writeln(
            '          emits(Right<Failure, '
            '$returnType>(expected$returnType)),',
          )
          ..writeln('        );');
      }
    } else {
      // Future test
      buffer.writeln('    test(');
      if (isVoid) {
        buffer.writeln(
          "      'should complete successfully "
          "when call to remote source is successful',",
        );
      } else {
        buffer.writeln(
          "      'should return Right<$returnType> "
          "when remote data source is successful',",
        );
      }
      buffer.writeln('      () async {');

      // Mock setup
      if (method.params != null) {
        final mockParams = method.params!
            .map((p) => 'any(${p.isNamed ? "named: '${p.name}'" : ''})')
            .join(', ');
        buffer.writeln(
          '        when(() => '
          'remoteDataSource.$methodName($mockParams)).thenAnswer(',
        );
      } else {
        buffer.writeln(
          '        when(() => remoteDataSource.$methodName()).thenAnswer(',
        );
      }

      if (isVoid) {
        buffer.writeln('          (_) async => Future.value(),');
      } else if (returnType.toLowerCase().startsWith('list')) {
        final innerType = returnType.substring(5, returnType.length - 1);
        buffer.writeln('          (_) async => expected${innerType}s,');
      } else {
        buffer.writeln('          (_) async => expected$returnType,');
      }
      buffer
        ..writeln('        );')
        ..writeln();

      // Test execution
      if (callParams.isNotEmpty) {
        buffer.writeln(
          '        final result = await repoImpl.$methodName($callParams);',
        );
      } else {
        buffer.writeln('        final result = await repoImpl.$methodName();');
      }
      buffer.writeln();

      // Expectation
      if (isVoid) {
        buffer.writeln(
          '        expect(result, equals(const Right<dynamic, void>(null)));',
        );
      } else if (returnType.toLowerCase().startsWith('list')) {
        final innerType = returnType.substring(5, returnType.length - 1);
        buffer.writeln(
          '        expect(result, '
          'equals(Right<Failure, $returnType>(expected${innerType}s)));',
        );
      } else {
        buffer.writeln(
          '        expect(result, equals(Right<Failure, '
          '$returnType>(expected$returnType)));',
        );
      }
    }

    buffer.writeln();

    // Verification
    if (method.params != null) {
      if (namedParams.isNotEmpty || positionalParams.isNotEmpty) {
        buffer
          ..writeln('        verify(')
          ..writeln('          () => remoteDataSource.$methodName(');
        if (callParams.isNotEmpty) {
          if (namedParams.isNotEmpty && positionalParams.isNotEmpty) {
            buffer.writeln('            $positionalParams,');
            for (final param in method.params!.where((p) => p.isNamed)) {
              buffer.writeln('            ${param.name}: ${param.name},');
            }
          } else if (namedParams.isNotEmpty) {
            for (final param in method.params!.where((p) => p.isNamed)) {
              buffer.writeln('            ${param.name}: ${param.name},');
            }
          } else {
            buffer.writeln('            $positionalParams,');
          }
        }
        buffer
          ..writeln('          ),')
          ..writeln('        ).called(1);');
      } else {
        buffer.writeln(
          '        verify(() => remoteDataSource.$methodName()).called(1);',
        );
      }
    } else {
      buffer.writeln(
        '        verify(() => remoteDataSource.$methodName()).called(1);',
      );
    }

    buffer
      ..writeln('        verifyNoMoreInteractions(remoteDataSource);')
      ..writeln('      },')
      ..writeln('    );')
      ..writeln();
  }

  void _generateFailureTest(
    StringBuffer buffer,
    IFunction method,
    String returnType,
    bool isStream,
    bool isVoid,
  ) {
    final methodName = method.name;
    final namedParams =
        method.params
            ?.where((p) => p.isNamed)
            .map((p) => '${p.name}: ${p.name}')
            .join(', ') ??
        '';
    final positionalParams =
        method.params?.where((p) => !p.isNamed).map((p) => p.name).join(', ') ??
        '';

    final callParams = method.params != null
        ? (namedParams.isNotEmpty && positionalParams.isNotEmpty)
              ? '$positionalParams, $namedParams'
              : namedParams.isNotEmpty
              ? namedParams
              : positionalParams
        : '';

    if (isStream) {
      buffer
        ..writeln('    test(')
        ..writeln(
          "      'should return a stream of Left<Failure> when "
          "remote data source throws '",
        )
        ..writeln("      'an error',")
        ..writeln('      () {');

      // Mock setup
      if (method.params != null) {
        final mockParams = method.params!
            .map((p) => 'any(${p.isNamed ? "named: '${p.name}'" : ''})')
            .join(', ');
        buffer.writeln(
          '        when(() => '
          'remoteDataSource.$methodName($mockParams)).thenAnswer(',
        );
      } else {
        buffer.writeln(
          '        when(() => remoteDataSource.$methodName()).thenAnswer(',
        );
      }

      buffer
        ..writeln('          (_) => Stream.error(')
        ..writeln('            ServerException(')
        ..writeln('              message: serverFailure.message,')
        ..writeln(
          '              statusCode: serverFailure.statusCode.toString(),',
        )
        ..writeln('            ),')
        ..writeln('          ),')
        ..writeln('        );')
        ..writeln();

      // Test execution
      if (callParams.isNotEmpty) {
        buffer.writeln(
          '        final stream = repoImpl.$methodName($callParams);',
        );
      } else {
        buffer.writeln('        final stream = repoImpl.$methodName();');
      }
      buffer
        ..writeln()
        // Expectation
        ..writeln('        expect(')
        ..writeln('          stream,')
        ..writeln(
          '          emits(equals(const Left<Failure, '
          '$returnType>(serverFailure))),',
        )
        ..writeln('        );');
    } else {
      // Future test
      buffer
        ..writeln('    test(')
        ..writeln(
          "      'should return [ServerFailure] when call to "
          "remote source is '",
        )
        ..writeln("      'unsuccessful',")
        ..writeln('      () async {');

      // Mock setup
      if (method.params != null) {
        final mockParams = method.params!
            .map((p) => 'any(${p.isNamed ? "named: '${p.name}'" : ''})')
            .join(', ');
        buffer.writeln(
          '        when(() => '
          'remoteDataSource.$methodName($mockParams)).thenThrow(',
        );
      } else {
        buffer.writeln(
          '        when(() => remoteDataSource.$methodName()).thenThrow(',
        );
      }

      buffer
        ..writeln(
          '          const ServerException(message: '
          "'message', statusCode: 'statusCode'),",
        )
        ..writeln('        );')
        ..writeln();

      // Test execution
      if (callParams.isNotEmpty) {
        buffer.writeln(
          '        final result = await repoImpl.$methodName($callParams);',
        );
      } else {
        buffer.writeln('        final result = await repoImpl.$methodName();');
      }
      buffer
        ..writeln()
        // Expectation
        ..writeln('        expect(')
        ..writeln('          result,')
        ..writeln('          equals(')
        ..writeln('            const Left<ServerFailure, dynamic>(')
        ..writeln(
          '              ServerFailure(message: '
          "'message', statusCode: 'statusCode'),",
        )
        ..writeln('            ),')
        ..writeln('          ),')
        ..writeln('        );');
    }

    buffer.writeln();

    // Verification
    if (method.params != null) {
      if (namedParams.isNotEmpty || positionalParams.isNotEmpty) {
        buffer
          ..writeln('        verify(')
          ..writeln('          () => remoteDataSource.$methodName(');
        if (callParams.isNotEmpty) {
          if (namedParams.isNotEmpty && positionalParams.isNotEmpty) {
            buffer.writeln('            $positionalParams,');
            for (final param in method.params!.where((p) => p.isNamed)) {
              buffer.writeln('            ${param.name}: ${param.name},');
            }
          } else if (namedParams.isNotEmpty) {
            for (final param in method.params!.where((p) => p.isNamed)) {
              buffer.writeln('            ${param.name}: ${param.name},');
            }
          } else {
            buffer.writeln('            $positionalParams,');
          }
        }
        buffer
          ..writeln('          ),')
          ..writeln('        ).called(1);');
      } else {
        buffer.writeln(
          '        verify(() => remoteDataSource.$methodName()).called(1);',
        );
      }
    } else {
      buffer.writeln(
        '        verify(() => remoteDataSource.$methodName()).called(1);',
      );
    }

    buffer
      ..writeln('        verifyNoMoreInteractions(remoteDataSource);')
      ..writeln('      },')
      ..writeln('    );')
      ..writeln();
  }
}

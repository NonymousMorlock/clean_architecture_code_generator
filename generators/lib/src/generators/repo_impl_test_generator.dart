// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'dart:io';
import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

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

    // Generate complete file with imports (imports are already in the generated code)
    final completeFile = '// GENERATED CODE - DO NOT MODIFY BY HAND\n\n$buffer';

    // Write to the test file
    try {
      File(testPath).writeAsStringSync(completeFile);
    } catch (e) {
      print('Warning: Could not write to $testPath: $e');
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

    final featureName =
        className.replaceAll('RepoTBG', '').replaceAll('Repo', '');
    final featureSnakeCase = featureName.snakeCase;

    // Generate imports
    _generateImports(buffer, featureName, featureSnakeCase, repoName,
        repoImplName, remoteDataSourceName);

    // Generate mock class
    buffer.writeln(
        'class $mockDataSourceName extends Mock implements $remoteDataSourceName {}');
    buffer.writeln();

    // Generate main test function
    buffer.writeln('void main() {');
    buffer.writeln('  late $mockDataSourceName remoteDataSource;');
    buffer.writeln('  late $repoImplName repoImpl;');
    buffer.writeln();

    // Generate test entities for registration
    _generateTestEntities(buffer, visitor, featureName);

    buffer.writeln('  setUp(() {');
    buffer.writeln('    remoteDataSource = $mockDataSourceName();');
    buffer.writeln('    repoImpl = $repoImplName(remoteDataSource);');
    buffer.writeln('  });');
    buffer.writeln();

    // Generate tests for each method
    for (final method in visitor.methods) {
      _generateMethodTest(buffer, method, featureName, remoteDataSourceName);
    }

    buffer.writeln('}');
  }

  void _generateImports(
      StringBuffer buffer,
      String featureName,
      String featureSnakeCase,
      String repoName,
      String repoImplName,
      String remoteDataSourceName) {
    // Load configuration to get app name
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final appName = config.appName;

    buffer.writeln('import \'package:dartz/dartz.dart\';');
    buffer.writeln('import \'package:flutter_test/flutter_test.dart\';');
    buffer.writeln('import \'package:mocktail/mocktail.dart\';');
    buffer.writeln();
    buffer.writeln('// Core imports');
    buffer.writeln('import \'package:$appName/core/errors/exceptions.dart\';');
    buffer.writeln('import \'package:$appName/core/errors/failures.dart\';');
    buffer.writeln('import \'package:$appName/core/typedefs.dart\';');
    buffer.writeln();
    buffer.writeln('// Feature imports');
    buffer.writeln(
        'import \'package:$appName/features/$featureSnakeCase/data/datasources/${featureSnakeCase}_remote_data_source.dart\';');
    buffer.writeln(
        'import \'package:$appName/features/$featureSnakeCase/data/models/${featureSnakeCase}_model.dart\';');
    buffer.writeln(
        'import \'package:$appName/features/$featureSnakeCase/data/repositories/${featureSnakeCase}_repository_impl.dart\';');
    buffer.writeln(
        'import \'package:$appName/features/$featureSnakeCase/domain/entities/$featureSnakeCase.dart\';');
    buffer.writeln();
  }

  void _generateTestEntities(
      StringBuffer buffer, RepoVisitor visitor, String featureName) {
    // Find entity types used in methods
    final entityTypes = <String>{};

    for (final method in visitor.methods) {
      final returnType = method.returnType.rightType;
      if (returnType.contains(featureName)) {
        entityTypes.add(featureName);
      }

      // Check parameters for entity types
      if (method.params != null) {
        for (final param in method.params!) {
          if (param.type.contains(featureName)) {
            entityTypes.add(featureName);
          }
        }
      }
    }

    // Generate test entities
    for (final entityType in entityTypes) {
      buffer.writeln('  final t$entityType = $entityType.empty();');
    }

    if (entityTypes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('  setUpAll(() {');
      for (final entityType in entityTypes) {
        buffer.writeln('    registerFallbackValue(t$entityType);');
      }
      buffer.writeln('  });');
      buffer.writeln();
    }
  }

  void _generateMethodTest(StringBuffer buffer, IFunction method,
      String featureName, String remoteDataSourceName) {
    final methodName = method.name;
    final returnType = method.returnType.rightType;
    final isStream = method.returnType.startsWith('Stream');
    final isVoid = returnType.toLowerCase().trim() == 'void';

    buffer.writeln('  group(\'$methodName\', () {');

    // Generate test data
    _generateTestData(buffer, method, returnType, featureName);

    // Generate success test
    _generateSuccessTest(
        buffer, method, returnType, isStream, isVoid, featureName);

    // Generate failure test
    _generateFailureTest(buffer, method, returnType, isStream, isVoid);

    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateTestData(StringBuffer buffer, IFunction method,
      String returnType, String featureName) {
    if (returnType.toLowerCase().startsWith('list')) {
      final innerType = returnType.substring(5, returnType.length - 1);
      final modelType = '${innerType}Model';
      buffer.writeln('    final expected${innerType}s = [');
      buffer.writeln('      $modelType.empty(),');
      buffer.writeln('      $modelType.empty().copyWith(id: \'1\'),');
      buffer.writeln('    ];');
    } else if (!returnType.toLowerCase().trim().contains('void')) {
      final modelType = '${returnType}Model';
      buffer.writeln('    final expected$returnType = $modelType.empty();');
    }

    // Generate parameter constants
    if (method.params != null) {
      for (final param in method.params!) {
        if (param.type.toLowerCase() == 'string') {
          buffer.writeln(
              '    const ${param.name} = \'sample${param.name.upperCamelCase}\';');
        } else if (param.type.toLowerCase() == 'int') {
          buffer.writeln('    const ${param.name} = 1;');
        } else if (param.type.toLowerCase() == 'bool') {
          buffer.writeln('    const ${param.name} = true;');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('    const serverFailure = ServerFailure(');
    buffer.writeln('      message: \'Server error\',');
    buffer.writeln('      statusCode: \'500\',');
    buffer.writeln('    );');
    buffer.writeln();
  }

  void _generateSuccessTest(StringBuffer buffer, IFunction method,
      String returnType, bool isStream, bool isVoid, String featureName) {
    final methodName = method.name;
    final namedParams = method.params
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
      buffer.writeln('    test(');
      buffer.writeln(
          '      \'should return a stream of Right<$returnType> when remote data source \'');
      buffer.writeln('      \'is successful\',');
      buffer.writeln('      () {');

      // Mock setup
      if (method.params != null) {
        final mockParams = method.params!
            .map((p) => 'any(${p.isNamed ? 'named: \'${p.name}\'' : ''})')
            .join(', ');
        buffer.writeln(
            '        when(() => remoteDataSource.$methodName($mockParams)).thenAnswer(');
      } else {
        buffer.writeln(
            '        when(() => remoteDataSource.$methodName()).thenAnswer(');
      }

      if (returnType.toLowerCase().startsWith('list')) {
        final innerType = returnType.substring(5, returnType.length - 1);
        buffer.writeln('          (_) => Stream.value(expected${innerType}s),');
      } else {
        buffer.writeln('          (_) => Stream.value(expected$returnType),');
      }
      buffer.writeln('        );');
      buffer.writeln();

      // Test execution
      if (callParams.isNotEmpty) {
        buffer.writeln(
            '        final stream = repoImpl.$methodName($callParams);');
      } else {
        buffer.writeln('        final stream = repoImpl.$methodName();');
      }
      buffer.writeln();

      // Expectation
      if (returnType.toLowerCase().startsWith('list')) {
        final innerType = returnType.substring(5, returnType.length - 1);
        buffer.writeln('        expect(');
        buffer.writeln('          stream,');
        buffer.writeln(
            '          emits(Right<Failure, $returnType>(expected${innerType}s)),');
        buffer.writeln('        );');
      } else {
        buffer.writeln('        expect(');
        buffer.writeln('          stream,');
        buffer.writeln(
            '          emits(Right<Failure, $returnType>(expected$returnType)),');
        buffer.writeln('        );');
      }
    } else {
      // Future test
      buffer.writeln('    test(');
      if (isVoid) {
        buffer.writeln(
            '      \'should complete successfully when call to remote source is successful\',');
      } else {
        buffer.writeln(
            '      \'should return Right<$returnType> when remote data source is successful\',');
      }
      buffer.writeln('      () async {');

      // Mock setup
      if (method.params != null) {
        final mockParams = method.params!
            .map((p) => 'any(${p.isNamed ? 'named: \'${p.name}\'' : ''})')
            .join(', ');
        buffer.writeln(
            '        when(() => remoteDataSource.$methodName($mockParams)).thenAnswer(');
      } else {
        buffer.writeln(
            '        when(() => remoteDataSource.$methodName()).thenAnswer(');
      }

      if (isVoid) {
        buffer.writeln('          (_) async => Future.value(),');
      } else if (returnType.toLowerCase().startsWith('list')) {
        final innerType = returnType.substring(5, returnType.length - 1);
        buffer.writeln('          (_) async => expected${innerType}s,');
      } else {
        buffer.writeln('          (_) async => expected$returnType,');
      }
      buffer.writeln('        );');
      buffer.writeln();

      // Test execution
      if (callParams.isNotEmpty) {
        buffer.writeln(
            '        final result = await repoImpl.$methodName($callParams);');
      } else {
        buffer.writeln('        final result = await repoImpl.$methodName();');
      }
      buffer.writeln();

      // Expectation
      if (isVoid) {
        buffer.writeln(
            '        expect(result, equals(const Right<dynamic, void>(null)));');
      } else if (returnType.toLowerCase().startsWith('list')) {
        final innerType = returnType.substring(5, returnType.length - 1);
        buffer.writeln(
            '        expect(result, equals(Right<Failure, $returnType>(expected${innerType}s)));');
      } else {
        buffer.writeln(
            '        expect(result, equals(Right<Failure, $returnType>(expected$returnType)));');
      }
    }

    buffer.writeln();

    // Verification
    if (method.params != null) {
      if (namedParams.isNotEmpty || positionalParams.isNotEmpty) {
        buffer.writeln('        verify(');
        buffer.writeln('          () => remoteDataSource.$methodName(');
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
        buffer.writeln('          ),');
        buffer.writeln('        ).called(1);');
      } else {
        buffer.writeln(
            '        verify(() => remoteDataSource.$methodName()).called(1);');
      }
    } else {
      buffer.writeln(
          '        verify(() => remoteDataSource.$methodName()).called(1);');
    }

    buffer.writeln('        verifyNoMoreInteractions(remoteDataSource);');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln();
  }

  void _generateFailureTest(StringBuffer buffer, IFunction method,
      String returnType, bool isStream, bool isVoid) {
    final methodName = method.name;
    final namedParams = method.params
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
      buffer.writeln('    test(');
      buffer.writeln(
          '      \'should return a stream of Left<Failure> when remote data source throws \'');
      buffer.writeln('      \'an error\',');
      buffer.writeln('      () {');

      // Mock setup
      if (method.params != null) {
        final mockParams = method.params!
            .map((p) => 'any(${p.isNamed ? 'named: \'${p.name}\'' : ''})')
            .join(', ');
        buffer.writeln(
            '        when(() => remoteDataSource.$methodName($mockParams)).thenAnswer(');
      } else {
        buffer.writeln(
            '        when(() => remoteDataSource.$methodName()).thenAnswer(');
      }

      buffer.writeln('          (_) => Stream.error(');
      buffer.writeln('            ServerException(');
      buffer.writeln('              message: serverFailure.message,');
      buffer.writeln(
          '              statusCode: serverFailure.statusCode.toString(),');
      buffer.writeln('            ),');
      buffer.writeln('          ),');
      buffer.writeln('        );');
      buffer.writeln();

      // Test execution
      if (callParams.isNotEmpty) {
        buffer.writeln(
            '        final stream = repoImpl.$methodName($callParams);');
      } else {
        buffer.writeln('        final stream = repoImpl.$methodName();');
      }
      buffer.writeln();

      // Expectation
      buffer.writeln('        expect(');
      buffer.writeln('          stream,');
      buffer.writeln(
          '          emits(equals(const Left<Failure, $returnType>(serverFailure))),');
      buffer.writeln('        );');
    } else {
      // Future test
      buffer.writeln('    test(');
      buffer.writeln(
          '      \'should return [ServerFailure] when call to remote source is \'');
      buffer.writeln('      \'unsuccessful\',');
      buffer.writeln('      () async {');

      // Mock setup
      if (method.params != null) {
        final mockParams = method.params!
            .map((p) => 'any(${p.isNamed ? 'named: \'${p.name}\'' : ''})')
            .join(', ');
        buffer.writeln(
            '        when(() => remoteDataSource.$methodName($mockParams)).thenThrow(');
      } else {
        buffer.writeln(
            '        when(() => remoteDataSource.$methodName()).thenThrow(');
      }

      buffer.writeln(
          '          const ServerException(message: \'message\', statusCode: \'statusCode\'),');
      buffer.writeln('        );');
      buffer.writeln();

      // Test execution
      if (callParams.isNotEmpty) {
        buffer.writeln(
            '        final result = await repoImpl.$methodName($callParams);');
      } else {
        buffer.writeln('        final result = await repoImpl.$methodName();');
      }
      buffer.writeln();

      // Expectation
      buffer.writeln('        expect(');
      buffer.writeln('          result,');
      buffer.writeln('          equals(');
      buffer.writeln('            const Left<ServerFailure, dynamic>(');
      buffer.writeln(
          '              ServerFailure(message: \'message\', statusCode: \'statusCode\'),');
      buffer.writeln('            ),');
      buffer.writeln('          ),');
      buffer.writeln('        );');
    }

    buffer.writeln();

    // Verification
    if (method.params != null) {
      if (namedParams.isNotEmpty || positionalParams.isNotEmpty) {
        buffer.writeln('        verify(');
        buffer.writeln('          () => remoteDataSource.$methodName(');
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
        buffer.writeln('          ),');
        buffer.writeln('        ).called(1);');
      } else {
        buffer.writeln(
            '        verify(() => remoteDataSource.$methodName()).called(1);');
      }
    } else {
      buffer.writeln(
          '        verify(() => remoteDataSource.$methodName()).called(1);');
    }

    buffer.writeln('        verifyNoMoreInteractions(remoteDataSource);');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln();
  }
}

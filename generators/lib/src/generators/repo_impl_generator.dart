// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/repo_visitor_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/core/services/functions.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating repository implementation classes.
///
/// Processes classes annotated with `@RepoImplGenAnnotation` and generates
/// repository implementation classes in the data layer.
class RepoImplGenerator extends GeneratorForAnnotation<RepoImplGenAnnotation> {
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
      return _generateMultiFile(visitor, writer);
    }

    // Default behavior: generate to .g.dart
    final buffer = StringBuffer();
    repository(buffer: buffer, visitor: visitor);
    return buffer.toString();
  }

  String _generateMultiFile(
    RepoVisitor visitor,
    FeatureFileWriter writer,
  ) {
    final featureName = writer.extractFeatureName(repoName: visitor.className);
    if (featureName == null) {
      // Fallback to default
      final buffer = StringBuffer();
      repository(buffer: buffer, visitor: visitor);
      return buffer.toString();
    }

    final baseName = writer.extractBaseName(visitor.className);
    final repoImplPath = writer.getRepoImplPath(featureName, baseName);

    // Generate repository implementation code
    final buffer = StringBuffer();
    repository(buffer: buffer, visitor: visitor);

    // Generate complete file with imports
    final imports = writer.generateSmartRepoImplImports(
      candidates: visitor.discoverRequiredEntities(),
      featureName: featureName,
    );
    final completeFile = writer.generateCompleteFile(
      imports: imports,
      generatedCode: buffer.toString(),
    );

    // Write to the repository implementation file
    try {
      writer.writeToFile(repoImplPath, completeFile);
      // Return a minimal marker for the .g.dart file
      return '// Repository implementation written to: $repoImplPath\n';
    } on Exception catch (e) {
      stderr.writeln('Warning: Could not write to $repoImplPath: $e');
      return '// Error: Could not write repository implementation to file.\n:'
          ' $e\n';
    }
  }

  /// Generates the repository implementation class.
  ///
  /// Creates a concrete implementation of the repository interface
  /// that delegates to data sources and handles data transformations.
  void repository({
    required StringBuffer buffer,
    required RepoVisitor visitor,
  }) {
    final repoName = visitor.className;
    final className = '${repoName}Impl';
    buffer
      ..writeln('class $className implements $repoName {')
      ..writeln('const $className(this._remoteDataSource);')
      ..writeln()
      ..writeln(
        'final '
        '${repoName.substring(0, repoName.length - 4)}RemoteDataSrc '
        '_remoteDataSource;',
      )
      ..writeln();
    for (final method in visitor.methods) {
      final returnType = method.returnType.rightType;
      final result = returnType.trim() != 'void' ? 'final result = ' : '';
      final returnResult = returnType.trim() != 'void' ? 'result' : 'null';
      buffer.writeln('@override');
      final isStream = method.returnType.startsWith('Stream');
      final asyncText = isStream ? '' : 'async';
      final asynchronyType = isStream ? 'Stream' : 'Future';
      if (method.params != null) {
        final params = method.params!
            .map((param) => paramToString(method, param))
            .join(', ');
        buffer.writeln(
          'Result$asynchronyType<$returnType> ${method.name}($params) '
          '$asyncText {',
        );
        if (!isStream) {
          final commaSeparatedArguments = method.params!
              .map(_paramToArg)
              .join(', ');
          buffer
            ..writeln('try {')
            ..writeln(
              '${result}await '
              '_remoteDataSource.${method.name}($commaSeparatedArguments);',
            )
            ..writeln(
              'return '
              "${returnResult == 'null' ? 'const ' : ''}Right($returnResult);",
            )
            ..writeln('} on ServerException catch (e) {')
            ..writeln(
              'return Left(ServerFailure(message: e.message, '
              'statusCode: e.statusCode));',
            )
            ..writeln('}');
        } else {
          final commaSeparatedArguments = method.params!
              .map(_paramToArg)
              .join(', ');
          buffer.writeln(
            'return _remoteDataSource.${method.name}'
            '($commaSeparatedArguments).transform(',
          );
          _writeTransformer(buffer, method: method);
          buffer.writeln(');');
        }
        buffer.writeln('}');
      } else {
        buffer.writeln(
          'Result$asynchronyType<$returnType> ${method.name}'
          '() $asyncText {',
        );
        if (!isStream) {
          buffer
            ..writeln('try {')
            ..writeln('${result}await _remoteDataSource.${method.name}();')
            ..writeln(
              'return '
              "${returnResult == 'null' ? 'const ' : ''}Right($returnResult);",
            )
            ..writeln('} on ServerException catch (e) {')
            ..writeln(
              'return Left(ServerFailure(message: e.message, '
              'statusCode: e.statusCode));',
            )
            ..writeln('}');
        } else {
          buffer.writeln(
            'return _remoteDataSource.${method.name}().transform(',
          );
          _writeTransformer(buffer, method: method);
          buffer.writeln(');');
        }
        buffer.writeln('}');
      }
    }
    buffer.writeln('}');
  }

  String _paramToArg(Param param) {
    if (param.isNamed) {
      return '${param.name}: ${param.name}';
    } else {
      return param.name;
    }
  }

  void _writeTransformer(StringBuffer buffer, {required IFunction method}) {
    // left of transformer is the Stream's return type
    // right side is the return type of the calling function, in this
    // case, our repoImpl method
    final modelReturnType = method.returnType.modelizeType;
    buffer
      ..writeln(
        'StreamTransformer<'
        '$modelReturnType, ${method.returnType}'
        '>.fromHandlers(',
      )
      ..writeln('handleData: (data, sink) {')
      ..writeln('sink.add(Right(data));')
      ..writeln('},')
      ..writeln('handleError: (error, stackTrace, sink) {')
      ..writeln('if (error is ServerException) {')
      ..writeln(
        'sink.add(Left(ServerFailure(message: error.message,'
        ' statusCode: error.statusCode,),),);',
      )
      ..writeln('} else {')
      ..writeln(
        'sink.add(Left(ServerFailure(message: '
        "'Something went wrong'(), statusCode: 500,),),);",
      )
      ..writeln('}')
      ..writeln('},')
      ..writeln('),');
  }
}

// ResultFuture<${method.returnType.rightType}>

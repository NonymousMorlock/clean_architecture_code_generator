// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating use case classes from repository annotations.
///
/// Processes classes annotated with `@UsecaseGenAnnotation` and generates
/// use case classes for each repository method.
class UsecaseGenerator extends GeneratorForAnnotation<UsecaseGenAnnotation> {
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

    // Default behavior: generate all usecases to .g.dart
    final buffer = StringBuffer();
    for (final method in visitor.methods) {
      usecase(buffer: buffer, visitor: visitor, method: method);
    }
    return buffer.toString();
  }

  String _generateMultiFile(
    RepoVisitor visitor,
    FeatureFileWriter writer,
    BuildStep buildStep,
  ) {
    final featureName = writer.extractFeatureName(repoName: visitor.className);
    if (featureName == null) {
      // Fallback to default
      final buffer = StringBuffer();
      for (final method in visitor.methods) {
        usecase(buffer: buffer, visitor: visitor, method: method);
      }
      return buffer.toString();
    }

    final baseName = writer.extractBaseName(visitor.className);
    final results = <String>[];

    // Generate each usecase in its own file
    for (final method in visitor.methods) {
      final usecasePath = writer.getUsecasePath(featureName, method.name);

      // Generate usecase code
      final buffer = StringBuffer();
      usecase(buffer: buffer, visitor: visitor, method: method);

      // Generate complete file with imports
      final needsCustomParams =
          method.params != null && method.params!.length > 1;
      final isStream = method.returnType.startsWith('Stream');
      final imports = writer.getUsecaseImports(
        featureName,
        baseName,
        method.name,
        hasParams: needsCustomParams,
        isStream: isStream,
      );

      final completeFile = writer.generateCompleteFile(
        imports: imports,
        generatedCode: buffer.toString(),
        header: '// GENERATED CODE - DO NOT MODIFY BY HAND',
      );

      // Write to the usecase file
      try {
        File(usecasePath).writeAsStringSync(completeFile);
        results.add('// Usecase ${method.name} written to: $usecasePath');
      } on Exception catch (e) {
        stderr.writeln('Warning: Could not write to $usecasePath: $e');
        results.add('// Error writing usecase ${method.name}: $e');
      }
    }

    // Return markers for the .g.dart file
    return '${results.join('\n')}\n';
  }

  // if function params is greter than 1, then create
  // params class else just use it

  /// Generates a use case class for a repository method.
  ///
  /// Creates a use case class following the clean architecture pattern
  /// with call method and parameter handling.
  void usecase({
    required StringBuffer buffer,
    required RepoVisitor visitor,
    required IFunction method,
  }) {
    final repoName = visitor.className;
    final className = method.name.upperCamelCase;
    final needsCustomParams =
        method.params != null && method.params!.length > 1;
    final param = method.params != null
        ? method.params!.length > 1
              ? '${className}Params'
              : method.params![0].type
        : null;
    final returnType = method.returnType.rightType;
    final isStream = method.returnType.startsWith('Stream');
    final usecaseTypePrefix = isStream ? 'Stream' : '';
    final usecaseType = method.params != null
        ? '${usecaseTypePrefix}UsecaseWithParams<$returnType, $param>'
        : '${usecaseTypePrefix}UsecaseWithoutParams<$returnType>';
    buffer
      ..writeln('class $className implements $usecaseType {')
      ..writeln('const $className(this._repo);')
      ..writeln()
      ..writeln('final $repoName _repo;')
      ..writeln()
      ..writeln('@override');
    final asynchronyType = isStream ? 'Stream' : 'Future';
    buffer.writeln(
      'Result$asynchronyType<$returnType> '
      'call(${param == null ? '' : '$param params'}) =>',
    );
    callBody(
      buffer: buffer,
      needsCustomParams: needsCustomParams,
      method: method,
      param: param,
    );
    buffer.writeln('}');
    if (needsCustomParams) {
      buffer.writeln();
      customParam(paramName: param!, params: method.params!, buffer: buffer);
    }
  }

  /// Generates the call method body for the use case.
  ///
  /// Handles parameter passing to the repository method.
  void callBody({
    required StringBuffer buffer,
    required bool needsCustomParams,
    required IFunction method,
    dynamic param,
  }) {
    if (!needsCustomParams) {
      buffer.writeln('_repo.${method.name}(${param == null ? '' : 'params'});');
    } else {
      buffer.writeln('_repo.${method.name}(');
      for (final param in method.params!) {
        buffer.writeln('${param.name}: params.${param.name},');
      }
      buffer.writeln(');');
    }
  }

  /// Generates a custom parameter class for use cases with multiple parameters.
  ///
  /// Creates an Equatable class to hold multiple parameters.
  void customParam({
    required String paramName,
    required List<Param> params,
    required StringBuffer buffer,
  }) {
    buffer
      ..writeln('class $paramName extends Equatable {')
      ..writeln('const $paramName({');
    for (final param in params) {
      buffer.writeln('required this.${param.name},');
    }
    buffer
      ..writeln('});')
      ..writeln();
    for (final param in params) {
      buffer.writeln('final ${param.type} ${param.name};');
    }
    buffer
      ..writeln()
      ..writeln('@override')
      ..writeln('List<dynamic> get props => [');
    for (final param in params) {
      buffer.writeln('${param.name},');
    }
    buffer
      ..writeln('];')
      ..writeln('}');
  }
}

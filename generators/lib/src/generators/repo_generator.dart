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
import 'package:generators/core/utils/utils.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating repository interface classes.
///
/// Processes classes annotated with `@RepoGenAnnotation` and generates
/// repository interfaces in the domain layer.
class RepoGenerator extends GeneratorForAnnotation<RepoGenAnnotation> {
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
    repo(buffer, visitor);
    return buffer.toString();
  }

  String _generateMultiFile(
    RepoVisitor visitor,
    FeatureFileWriter writer,
  ) {
    final featureName = writer.extractFeatureName(repoName: visitor.className);
    if (featureName == null) {
      // Fallback to default if feature name can't be extracted
      final buffer = StringBuffer();
      repo(buffer, visitor);
      return buffer.toString();
    }

    final baseName = writer.extractBaseName(visitor.className);
    final repoPath = writer.getDomainRepoPath(featureName, baseName);

    // Generate repository interface code
    final buffer = StringBuffer();
    repo(buffer, visitor);

    // Generate complete file with imports
    final imports = writer.generateSmartRepoImports(
      featureName: featureName,
      candidates: visitor.discoverRequiredEntities(),
    );
    final completeFile = writer.generateCompleteFile(
      imports: imports,
      generatedCode: buffer.toString(),
    );

    // Write to the actual repository file
    try {
      writer.writeToFile(repoPath, completeFile);
      // Return a minimal marker for the .g.dart file
      return '// Repository interface written to: $repoPath\n';
    } on Exception catch (e) {
      stderr.writeln('Warning: Could not write to $repoPath: $e');
      return '// Error: Could not write to $repoPath: $e\n';
    }
  }

  /// Generates the repository interface.
  ///
  /// Creates an abstract interface class defining the contract
  /// for repository implementations.
  void repo(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    Utils.oneMemberAbstractHandler(
      buffer: buffer,
      methodLength: visitor.methods.length,
    );
    buffer
      ..writeln('abstract interface class $className {')
      ..writeln('const $className();');
    for (final method in visitor.methods) {
      final returnType = method.returnType.rightType;
      final isStream = method.returnType.startsWith('Stream');
      final param = method.params == null
          ? ''
          : method.params!.map((e) => paramToString(method, e)).join(', ');
      final asynchronyType = isStream ? 'Stream' : 'Future';
      buffer.writeln(
        'Result$asynchronyType<$returnType> ${method.name}($param);',
      );
    }
    buffer.writeln('}');
  }
}

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/code_builder_extensions.dart';
import 'package:generators/core/extensions/repo_visitor_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
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
    final writer = FeatureFileWriter(config: config, buildStep: buildStep);
    final featureName = writer.extractFeatureName(repoName: visitor.className);

    if (writer.isMultiFileEnabled && featureName != null) {
      return _generateMultiFile(
        visitor: visitor,
        writer: writer,
        featureName: featureName,
      );
    }

    // Default behavior: generate to .g.dart
    final repoClass = repo(visitor);

    return writer.resolveGeneratedCode(
      library: Library((library) => library.body.add(repoClass)),
    );
  }

  String _generateMultiFile({
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
    required String featureName,
  }) {
    final repoPath = writer.getDomainRepoPath(featureName);

    // Generate repository interface code
    final repoBuilder = repo(visitor);

    // Generate complete file with imports
    final (:imports, :importComments) = writer.generateSmartRepoImports(
      featureName: featureName,
      candidates: visitor.discoverRequiredEntities(),
    );

    final completeFile = writer.resolveGeneratedCode(
      library: Library((library) {
        if (visitor.methods.length < 2) {
          library.comments.addAll([
            'I need this class to be an interface.',
            'ignore_for_file: one_member_abstracts',
          ]);
        }
        library
          ..body.add(repoBuilder)
          ..comments.addAll(importComments)
          ..directives.addAll(imports.map(Directive.import));
      }),
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
  Class repo(RepoVisitor visitor) {
    final className = visitor.className;
    return Class((builder) {
      builder
        ..name = className
        ..abstract = true
        ..modifier = ClassModifier.interface
        ..constructors.add(
          Constructor((builder) => builder..constant = true),
        )
        ..methods.addAll(
          visitor.methods.map(
            (method) {
              final returnType = method.returnType.rightType;
              final isStream = method.rawType.isDartAsyncStream;
              final asynchronyType = isStream ? 'Stream' : 'Future';
              return Method(
                (methodBuilder) {
                  methodBuilder
                    ..name = method.name
                    ..returns = TypeReference((ref) {
                      ref
                        ..symbol = 'Result$asynchronyType'
                        ..types.add(Reference(returnType));
                    })
                    ..addParamsFrom(method);
                },
              );
            },
          ),
        );
    });
  }
}

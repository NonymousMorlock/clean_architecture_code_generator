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

/// Generator for creating remote data source classes from
/// repository annotations.
///
/// Processes classes annotated with `@RemoteDataSrcGenAnnotation` and generates
/// corresponding remote data source interfaces and implementations.
class RemoteDataSrcGenerator
    extends GeneratorForAnnotation<RemoteDataSrcGenAnnotation> {
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
        config: config,
        featureName: featureName,
      );
    }

    // Default behavior: generate to .g.dart
    final contract = remoteDataSourceInterface(visitor: visitor);
    final contractImpl = remoteDataSourceImpl(visitor: visitor, config: config);
    return writer.resolveGeneratedCode(
      library: Library(
        (library) => library.body.addAll([contract, contractImpl]),
      ),
    );
  }

  String _generateMultiFile({
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
    required GeneratorConfig config,
    required String featureName,
  }) {
    final dataSourcePath = writer.getRemoteDataSrcPath(featureName);

    // Generate remote data source code
    final contract = remoteDataSourceInterface(visitor: visitor);
    final contractImpl = remoteDataSourceImpl(visitor: visitor, config: config);

    // Generate complete file with imports
    final (:imports, :importComments) = writer
        .generateSmartRemoteDataSrcImports(
          candidates: visitor.discoverRequiredEntities(),
          featureName: featureName,
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
          ..body.addAll([contract, contractImpl])
          ..comments.addAll(importComments)
          ..directives.addAll(imports.map(Directive.import));
      }),
    );

    // Write to the data source file
    try {
      writer.writeToFile(dataSourcePath, completeFile);
      // Return a minimal marker for the .g.dart file
      return '// Remote data source written to: $dataSourcePath\n';
    } on Exception catch (e) {
      stderr.writeln('Warning: Could not write to $dataSourcePath: $e');
      return '// Error: Could not write to $dataSourcePath: $e\n';
    }
  }

  /// Generates the remote data source interface
  ///
  /// Creates the abstract interface contract
  Class remoteDataSourceInterface({required RepoVisitor visitor}) {
    final repoName = visitor.className
        .replaceAll('TBG', '')
        .replaceAll('Repo', '');
    final className = '${repoName}RemoteDataSource';

    return Class((classBuilder) {
      classBuilder
        ..name = className
        ..abstract = true
        ..modifier = ClassModifier.interface
        ..constructors.add(
          Constructor((constructor) => constructor.constant = true),
        )
        ..methods.addAll(
          visitor.methods.map((method) {
            var returnType = method.returnType.rightType;
            if (returnType.isCustomType) returnType = returnType.modelizeType;
            final isStream = method.rawType.isDartAsyncStream;
            return Method((methodBuilder) {
              methodBuilder
                ..name = method.name
                ..returns = TypeReference((ref) {
                  ref
                    ..symbol = isStream ? 'Stream' : 'Future'
                    ..types.add(Reference(returnType));
                })
                ..addParamsFrom(method, useModels: true);
            });
          }),
        );
    });
  }

  /// Generates the remote data source implementation.
  ///
  /// Creates the concrete implementation class
  /// with dependency configurations based on the YAML config.
  Class remoteDataSourceImpl({
    required RepoVisitor visitor,
    required GeneratorConfig config,
  }) {
    final repoName = visitor.className
        .replaceAll('TBG', '')
        .replaceAll('Repo', '');
    final contractClassName = '${repoName}RemoteDataSource';

    final className = '${contractClassName}Impl';

    final dependencies = config.remoteDataSourceConfig.constructorDependencies;

    return Class((classBuilder) {
      classBuilder
        ..name = className
        ..implements.add(Reference(contractClassName))
        ..constructors.add(
          _generateConfigBasedConstructor(config.remoteDataSourceConfig),
        )
        ..fields.addAll(
          dependencies.map((dependency) {
            return Field((field) {
              field
                ..name = dependency.privatisedName
                ..type = Reference(dependency.type)
                ..modifier = FieldModifier.final$;
            });
          }),
        )
        ..methods.addAll(
          visitor.methods.map((method) {
            var returnType = method.returnType.rightType;
            if (returnType.isCustomType) returnType = returnType.modelizeType;
            final isStream = method.rawType.isDartAsyncStream;

            return Method((methodBuilder) {
              methodBuilder
                ..name = method.name
                ..annotations.add(const Reference('override'))
                ..returns = TypeReference((ref) {
                  ref
                    ..symbol = isStream ? 'Stream' : 'Future'
                    ..types.add(Reference(returnType));
                })
                ..modifier = isStream ? null : MethodModifier.async
                ..addParamsFrom(method, useModels: true)
                ..body = Block((block) {
                  block
                    ..statements.add(
                      Code('// TODO(${method.name}): implement ${method.name}'),
                    )
                    ..addExpression(
                      refer('UnimplementedError').newInstance([]).thrown,
                    );
                });
            });
          }),
        );
    });
  }

  Constructor _generateConfigBasedConstructor(
    RemoteDataSourceConfig config,
  ) {
    final dependencies = config.constructorDependencies;

    return Constructor((constructor) {
      constructor
        ..constant = true
        ..optionalParameters.addAll(
          dependencies.map((dependency) {
            return Parameter((param) {
              param
                ..name = dependency.name
                ..type = Reference(dependency.type)
                ..named = true
                ..required = true;
            });
          }),
        )
        ..initializers.addAll(
          dependencies.map((dependency) {
            return refer(
              dependency.privatisedName,
            ).assign(Reference(dependency.name)).code;
          }),
        );
    });
  }
}

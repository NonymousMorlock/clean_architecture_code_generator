import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/code_builder_extensions.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/core/extensions/i_function_extensions.dart';
import 'package:generators/core/extensions/repo_visitor_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
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
    final repoImplClass = repository(visitor: visitor);
    return writer.resolveGeneratedCode(
      library: Library((library) => library.body.add(repoImplClass)),
    );
  }

  String _generateMultiFile({
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
    required String featureName,
  }) {
    final repoImplPath = writer.getRepoImplPath(featureName);

    // Generate repository implementation code
    final repoImplClass = repository(visitor: visitor);

    final customStreamTypes = <String>{};
    var hasStream = false;
    for (final method in visitor.methods) {
      if (method.rawType.isDartAsyncStream) {
        hasStream = true;
        if (method.rawType.successType.hasCustomType) {
          customStreamTypes.add(
            method.rawType.deepestType.displayString(withNullability: false),
          );
        }
      }
    }

    // Generate complete file with imports
    final (:imports, :importComments) = writer.generateSmartRepoImplImports(
      candidates: visitor.discoverRequiredEntities(),
      featureName: featureName,
      hasStream: hasStream,
      customStreamTypes: customStreamTypes,
    );
    final completeFile = writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..body.add(repoImplClass)
          ..comments.addAll(importComments)
          ..directives.addAll(imports.map(Directive.import));
      }),
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
  Class repository({required RepoVisitor visitor}) {
    final repoName = visitor.className;
    final className = '${repoName}Impl';
    return Class((builder) {
      builder
        ..name = className
        ..implements.add(Reference(repoName))
        ..constructors.add(
          Constructor((builder) {
            builder
              ..constant = true
              ..requiredParameters.add(
                Parameter((param) {
                  param
                    ..name = '_remoteDataSource'
                    ..toThis = true;
                }),
              );
          }),
        )
        ..fields.add(
          Field(
            (builder) => builder
              ..name = '_remoteDataSource'
              ..modifier = FieldModifier.final$
              ..type = Reference(
                '${repoName.substring(0, repoName.length - 4)}RemoteDataSource',
              ),
          ),
        )
        ..methods.addAll(
          visitor.methods.map((method) {
            final returnType = method.returnType.rightType;
            final isStream = method.returnType.startsWith('Stream');
            final asynchronyType = isStream ? 'Stream' : 'Future';
            return Method((methodBuilder) {
              methodBuilder
                ..annotations.add(const Reference('override'))
                ..name = method.name
                ..returns = TypeReference((ref) {
                  ref
                    ..symbol = 'Result$asynchronyType'
                    ..types.add(Reference(returnType));
                })
                ..modifier = isStream ? null : MethodModifier.async
                ..addParamsFrom(method);
              if (!isStream) {
                methodBuilder.body = _buildAsyncMethodBody(
                  method: method,
                  isVoid: returnType.trim() == 'void',
                );
              } else {
                methodBuilder.body = _buildStreamMethodBody(method: method);
              }
            });
          }),
        );
    });
  }

  Block _buildAsyncMethodBody({
    required IFunction method,
    required bool isVoid,
  }) {
    return Block((bodyBuilder) {
      bodyBuilder.statements.add(const Code('try {'));

      final (:positional, :named) = method.extractArgs();

      // await _remoteDataSource.methodName(...);
      final callExpression = refer(
        '_remoteDataSource',
      ).property(method.name).call(positional, named).awaited;

      if (isVoid) {
        bodyBuilder
          ..addExpression(callExpression)
          ..addExpression(
            refer('Right').constInstance([refer('null')]).returned,
          );
      } else {
        bodyBuilder
          ..addExpression(declareFinal('result').assign(callExpression))
          ..addExpression(
            refer('Right').newInstance([refer('result')]).returned,
          );
      }

      bodyBuilder.statements.add(
        const Code('} on ServerException catch (e) {'),
      );

      final serverFailure = refer('ServerFailure').newInstance([], {
        'message': refer('e').property('message'),
        'statusCode': refer('e').property('statusCode'),
      });

      bodyBuilder.addExpression(
        refer('Left').newInstance([serverFailure]).returned,
      );

      bodyBuilder.statements.add(const Code('}'));
    });
  }

  Block _buildStreamMethodBody({required IFunction method}) {
    return Block((bodyBuilder) {
      // the 'handleData' closure: (data, sink) { ... }
      final handleData = Method(
        (method) => method
          ..requiredParameters.addAll([
            Parameter((param) => param.name = 'data'),
            Parameter((param) => param.name = 'sink'),
          ])
          ..body = Block((body) {
            body.addExpression(
              refer('sink').property('add').call([
                refer('Right').call([refer('data')]),
              ]),
            );
          }),
      ).closure;

      // the 'handleError' closure: (error, stackTrace, sink) { ... }
      final handleError = Method(
        (method) => method
          ..requiredParameters.addAll([
            Parameter((param) => param.name = 'error'),
            Parameter((param) => param.name = 'stackTrace'),
            Parameter((param) => param.name = 'sink'),
          ])
          ..body = Block((body) {
            body.statements.add(const Code('if (error is ServerException) {'));

            final serverFailure = refer('ServerFailure').newInstance([], {
              'message': refer('error').property('message'),
              'statusCode': refer('error').property('statusCode'),
            });

            body.addExpression(
              refer('sink').property('add').call([
                refer('Left').call([serverFailure]),
              ]),
            );

            body.statements.add(const Code('} else {'));

            final genericFailure = refer('ServerFailure').newInstance([], {
              'message': literalString('Something went wrong'),
              'statusCode': literalNum(500),
            });

            body.addExpression(
              refer('sink').property('add').call([
                refer('Left').constInstance([genericFailure]),
              ]),
            );

            body.statements.add(const Code('}'));
          }),
      ).closure;

      final transformer =
          TypeReference((refBuilder) {
            final modelType = Reference(
              method.returnType.rightType.modelizeType,
            );
            final returnType = Reference(method.returnType.innerType);
            refBuilder
              ..symbol = 'StreamTransformer'
              ..types.addAll([modelType, returnType]);
          }).newInstanceNamed(
            'fromHandlers',
            [],
            {
              'handleData': handleData,
              'handleError': handleError,
            },
          );
      final (:positional, :named) = method.extractArgs();

      // return _remoteDataSource.method(args).transform(transformer);
      bodyBuilder.addExpression(
        refer('_remoteDataSource')
            .property(method.name)
            .call(positional, named)
            .property('transform')
            .call([transformer])
            .returned,
      );
    });
  }
}

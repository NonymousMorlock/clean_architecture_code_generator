import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/core/extensions/param_extensions.dart';
import 'package:generators/generators.dart';
import 'package:generators/src/models/param.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating test files for use case classes.
///
/// Processes classes annotated with `@UsecaseTestGenAnnotation` and generates
/// comprehensive test files for use case classes.
class UsecaseTestGenerator
    extends GeneratorForAnnotation<UsecaseTestGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final writer = FeatureFileWriter(config: config, buildStep: buildStep);
    final className = visitor.className;
    final featureName = writer.extractFeatureName(repoName: className);

    if (writer.isMultiFileEnabled && featureName != null) {
      return _generateMultiFile(
        visitor: visitor,
        writer: writer,
        featureName: featureName,
        className: className,
      );
    }

    // Default behavior: generate all usecase tests to .g.dart
    return writer.resolveGeneratedCode(
      library: _generateLibraryForSingleFileOutput(
        visitor: visitor,
        className: className,
      ),
    );
  }

  String _generateMultiFile({
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
    required String featureName,
    required String className,
  }) {
    final results = <String>[];

    final mockFilePath = writer.getUsecasesRepoMockPath(featureName);

    final mockRepoClass = _generateMockRepoClass(className: className);

    final completeMockFile = writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..directives.addAll([
            Directive.import('package:mocktail/mocktail.dart'),
            Directive.import(
              writer.getRepositoryImportStatement(featureName: featureName),
            ),
          ])
          ..body.add(mockRepoClass);
      }),
    );

    try {
      writer.writeToFile(mockFilePath, completeMockFile);
      results.add('// Mock$className written to: $mockFilePath');
    } on Exception catch (e) {
      stderr.writeln('Warning: Could not write to $mockFilePath: $e');
      results.add('// Error writing Mock$className: $e');
    }

    for (final method in visitor.methods) {
      final usecaseTestFilePath = writer.getUsecaseTestPath(
        featureName: featureName,
        methodName: method.name,
      );

      final usecaseTestMethod = _generateUsecaseTestFromMethod(
        className: className,
        method: method,
      );

      final (:imports, :importComments) = writer
          .generateSmartUsecaseTestImports(
            candidates: Utils.discoverMethodEntities(method),
            featureName: featureName,
            methodName: method.name,
            repoName: className,
          );
      final completeFile = writer.resolveGeneratedCode(
        library: Library((library) {
          library
            ..body.add(usecaseTestMethod)
            ..comments.addAll(importComments)
            ..directives.addAll(imports.map(Directive.import));
        }),
      );

      // Write to the usecase file
      try {
        writer.writeToFile(usecaseTestFilePath, completeFile);
        results.add(
          '// Usecase test ${method.name} written to: $usecaseTestFilePath',
        );
      } on Exception catch (e) {
        stderr.writeln('Warning: Could not write to $usecaseTestFilePath: $e');
        results.add('// Error writing usecase test ${method.name}: $e\n');
      }
    }

    // Return markers for the .g.dart file
    return '${results.join('\n')}\n';
  }

  Class _generateMockRepoClass({
    required String className,
  }) {
    return Class((classBuilder) {
      classBuilder
        ..name = 'Mock$className'
        ..extend = const Reference('Mock')
        ..implements.add(Reference(className));
    });
  }

  Library _generateLibraryForSingleFileOutput({
    required RepoVisitor visitor,
    required String className,
  }) {
    return Library((library) {
      library
        ..comments.addAll([
          '// **************************************************************************',
          '// ${className.snakeCase}.mock.dart',
          '// **************************************************************************',
        ])
        ..body.addAll([
          _generateMockRepoClass(className: className),
          for (final method in visitor.methods)
            _generateUsecaseTestFromMethod(
              className: className,
              method: method,
            ),
        ]);
    });
  }

  Method _generateUsecaseTestFromMethod({
    required String className,
    required IFunction method,
  }) {
    return Method((methodBuilder) {
      methodBuilder
        ..name = 'main'
        ..returns = const Reference('void')
        ..body = Block((body) {
          body
            ..addExpression(
              declareVar(
                'repo',
                type: refer(className),
                late: true,
              ),
            )
            ..addExpression(
              declareVar(
                'usecase',
                type: refer(method.name.pascalCase),
                late: true,
              ),
            );

          if (method.hasParams) {
            for (final param in method.params!) {
              final variableName = 't${param.name.pascalCase}';
              final variableRef = param.rawType.isConst
                  ? declareConst(variableName)
                  : declareFinal(variableName);
              body.addExpression(
                variableRef.assign(
                  param.fallbackValue(
                    useConstForCollections: false,
                    skipIfNullable: false,
                  ),
                ),
              );
            }
          }

          final resultType = method.rawType.rightType;
          if (resultType is! VoidType) {
            const resultVariableName = 'tResult';
            final testResultRef = resultType.isConst
                ? declareConst(resultVariableName)
                : declareFinal(resultVariableName);

            body.addExpression(
              testResultRef.assign(
                resultType.fallbackValue(useConstForCollections: false),
              ),
            );
          }
          body
            ..addExpression(
              _generateSetUp(className: className, method: method),
            )
            ..addExpression(
              _generateActualTest(className: className, method: method),
            );
        });
    });
  }

  /// Generates the setUp method for use case tests.
  ///
  /// Initializes mocks and registers fallback values for parameters.
  Expression _generateSetUp({
    required String className,
    required IFunction method,
  }) {
    return refer('setUp').call([
      Method((methodBuilder) {
        methodBuilder.body = Block((body) {
          body
            ..addExpression(
              refer('repo').assign(refer('Mock$className').newInstance([])),
            )
            ..addExpression(
              refer('usecase').assign(
                refer(method.name.pascalCase).newInstance([refer('repo')]),
              ),
            );
          if (method.hasParams) {
            for (final param in method.params!) {
              if (param.type.isCustomType &&
                  !param.rawType.isDartCoreList &&
                  !param.rawType.isEnum) {
                body.addExpression(
                  refer(
                    'registerFallbackValue',
                  ).call([refer('t${param.name.pascalCase}')]),
                );
              }
            }
          }
        });
      }).closure,
    ]);
  }

  Expression _generateActualTest({
    required String className,
    required IFunction method,
  }) {
    final methodName = method.name;
    final isStream = method.rawType.isDartAsyncStream;

    return refer('test').call([
      literalString('should call the [$className.$methodName]'),
      Method((methodBuilder) {
        if (!isStream) {
          methodBuilder.modifier = MethodModifier.async;
        }

        final positionalArgumentsWithAny = <Expression>[];
        final namedArgumentsWithAny = <String, Expression>{};
        final positionalArgumentsWithTest = <Expression>[];
        final namedArgumentsWithTest = <String, Expression>{};
        for (final param in method.params ?? <Param>[]) {
          if (param.isNamed) {
            namedArgumentsWithAny[param.name] = refer(
              'any',
            ).call([], {'named': literalString(param.name)});
            namedArgumentsWithTest[param.name] = refer(
              't${param.name.pascalCase}',
            );
          } else {
            positionalArgumentsWithAny.add(refer('any').call([]));
            positionalArgumentsWithTest.add(refer('t${param.name.pascalCase}'));
          }
        }
        final useLambdas = Utils.shouldUseLambdaBody(
          methodHasParams: method.hasParams,
          namedArgumentsLength: namedArgumentsWithAny.length,
          positionalWhenArgumentsLength: positionalArgumentsWithAny.length,
        );

        methodBuilder.body = Block((body) {
          final responsePayload = method.rawType.rightType is VoidType
              ? literalNull
              : refer('tResult');
          // TODO(Test): Test this with various return types to
          //  make sure it uses a const instance ONLY when appropriate
          final isConst =
              responsePayload == literalNull ||
              method.rawType.rightType.isConst;
          // Arrange
          body.addExpression(
            refer('when')
                .call([
                  Method((methodBuilder) {
                    final body = refer('repo')
                        .property(methodName)
                        .call(
                          positionalArgumentsWithAny,
                          namedArgumentsWithAny,
                        );
                    methodBuilder
                      ..lambda = useLambdas
                      ..body = useLambdas
                          ? body.code
                          : Block(
                              (block) => block.addExpression(body.returned),
                            );
                  }).closure,
                ])
                .property('thenAnswer')
                .call([
                  Method((methodBuilder) {
                    final responseRef = isConst
                        ? refer('Right').constInstance([responsePayload])
                        : refer('Right').newInstance([responsePayload]);

                    Expression body;

                    if (!isStream) {
                      methodBuilder.modifier = MethodModifier.async;
                      body = responseRef;
                    } else {
                      body = refer(
                        'Stream',
                      ).property('value').call([responseRef]);
                    }
                    methodBuilder
                      ..requiredParameters.add(
                        Parameter((param) => param.name = '_'),
                      )
                      ..lambda = true
                      ..body = body.code;
                  }).closure,
                ]),
          );

          // Act
          final resultName = isStream ? 'stream' : 'result';
          final paramsClassName = '${methodName.pascalCase}Params';
          final needsCustomParams =
              method.params != null && method.params!.length > 1;
          final customParamsRef = refer(paramsClassName);
          final customParamsIsConst =
              needsCustomParams &&
              method.params!.every((param) => param.rawType.isConst);
          final paramArguments = {
            for (final param in method.params!)
              param.name: refer('t${param.name.pascalCase}'),
          };
          final customParams = needsCustomParams
              ? (customParamsIsConst
                    ? customParamsRef.constInstance([], paramArguments)
                    : customParamsRef.newInstance([], paramArguments))
              : null;
          final resultAssignment = refer('usecase').call(
            [
              if (!needsCustomParams && method.hasParams)
                refer('t${method.params!.first.name.pascalCase}')
              else if (needsCustomParams)
                customParams!,
            ],
          );
          body.addExpression(
            declareFinal(
              resultName,
            ).assign(isStream ? resultAssignment : resultAssignment.awaited),
          );

          // Assert
          final expectedRef = TypeReference((ref) {
            ref
              ..symbol = 'Right'
              ..types.addAll([
                const Reference('Failure'),
                refer(method.rawType.rightType.displayString()),
              ]);
          });
          body
            ..addExpression(
              refer(
                'expect',
              ).call([
                refer(resultName),
                refer(isStream ? 'emits' : 'equals').call([
                  if (isConst)
                    expectedRef.constInstance([responsePayload])
                  else
                    expectedRef.newInstance([responsePayload]),
                ]),
              ]),
            )
            ..addExpression(
              refer('verify')
                  .call([
                    Method((methodBuilder) {
                      final body = refer('repo')
                          .property(methodName)
                          .call(
                            positionalArgumentsWithTest,
                            namedArgumentsWithTest,
                          );
                      methodBuilder
                        ..lambda = useLambdas
                        ..body = useLambdas
                            ? body.code
                            : Block((block) => block.addExpression(body));
                    }).closure,
                  ])
                  .property('called')
                  .call([literalNum(1)]),
            )
            ..addExpression(
              refer('verifyNoMoreInteractions').call([refer('repo')]),
            );
        });
      }).closure,
    ]);
  }
}

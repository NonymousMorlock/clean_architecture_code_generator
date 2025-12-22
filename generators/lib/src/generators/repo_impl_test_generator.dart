import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/core/extensions/param_extensions.dart';
import 'package:generators/core/extensions/repo_visitor_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/core/utils/utils.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/models/param.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Arguments for generating test methods.
typedef TestMethodArgs = ({
  List<Expression> positionalWhenArguments,
  List<Expression> positionalVerifyArguments,
  Map<String, Expression> namedWhenArguments,
  Map<String, Expression> namedVerifyArguments,
});

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

    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final writer = FeatureFileWriter(config: config, buildStep: buildStep);

    final methodArguments = _preprocessTestArgs(methods: visitor.methods);

    final className = visitor.className;
    final featureName = writer.extractFeatureName(repoName: visitor.className);

    final repoName = className.replaceAll('TBG', '');
    final repoImplName = '${repoName}Impl';

    if (writer.isMultiFileEnabled && featureName != null) {
      return _generateMultiFile(
        visitor: visitor,
        writer: writer,
        featureName: featureName,
        repoImplName: repoImplName,
        methodArguments: methodArguments,
      );
    }

    final remoteDataSourceName =
        '${featureName?.pascalCase ?? writer.extractBaseName(repoName)}'
        'RemoteDataSource';

    // Default behavior: generate to .g.dart
    return writer.resolveGeneratedCode(
      library: _generateLibraryForSingleFileOutput(
        repoImplName: repoImplName,
        remoteDataSourceName: remoteDataSourceName,
        visitor: visitor,
        methodArguments: methodArguments,
      ),
    );
  }

  String _generateMultiFile({
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
    required String featureName,
    required String repoImplName,
    required Map<String, TestMethodArgs> methodArguments,
  }) {
    final remoteDataSourceName = '${featureName.pascalCase}RemoteDataSource';
    final testPath = writer.getRepoImplTestPath(featureName);

    final (:imports, :importComments) = writer.generateSmartRepoImplTestImports(
      featureName: featureName,
      candidates: visitor.discoverRequiredEntities(),
    );

    final mockDataSourceClass = _generateMockDataSourceClass(
      remoteDataSourceName: remoteDataSourceName,
    );

    final repoImplTest = _generateRepoImplTest(
      remoteDataSourceName: remoteDataSourceName,
      repoImplName: repoImplName,
      visitor: visitor,
      methodArguments: methodArguments,
    );

    // Generate complete file with imports
    final completeFile = writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..body.addAll([mockDataSourceClass, repoImplTest])
          ..comments.addAll(importComments)
          ..directives.addAll(imports.map(Directive.import));
      }),
    );

    // Write to the test file
    try {
      writer.writeToFile(testPath, completeFile);
      return '// Repository implementation test written to: $testPath\n';
    } on Exception catch (e) {
      stderr.writeln('Warning: Could not write to $testPath: $e');
      return '// Error: Could not write to $testPath\n: $e\n';
    }
  }

  Map<String, TestMethodArgs> _preprocessTestArgs({
    required List<IFunction> methods,
  }) {
    final argumentMap = <String, TestMethodArgs>{};
    for (final method in methods) {
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
      argumentMap[method.name] = (
        positionalWhenArguments: positionalArgumentsWithAny,
        positionalVerifyArguments: positionalArgumentsWithTest,
        namedWhenArguments: namedArgumentsWithAny,
        namedVerifyArguments: namedArgumentsWithTest,
      );
    }

    return argumentMap;
  }

  Library _generateLibraryForSingleFileOutput({
    required String repoImplName,
    required String remoteDataSourceName,
    required RepoVisitor visitor,
    required Map<String, TestMethodArgs> methodArguments,
  }) {
    return Library((library) {
      library.body.addAll([
        _generateMockDataSourceClass(
          remoteDataSourceName: remoteDataSourceName,
        ),
        _generateRepoImplTest(
          remoteDataSourceName: remoteDataSourceName,
          repoImplName: repoImplName,
          visitor: visitor,
          methodArguments: methodArguments,
        ),
      ]);
    });
  }

  Method _generateRepoImplTest({
    required String remoteDataSourceName,
    required String repoImplName,
    required RepoVisitor visitor,
    required Map<String, TestMethodArgs> methodArguments,
  }) {
    remoteDataSourceName = remoteDataSourceName.pascalCase;
    repoImplName = repoImplName.pascalCase;

    return Method((methodBuilder) {
      methodBuilder
        ..name = 'main'
        ..returns = const Reference('void')
        ..body = Block((body) {
          body
            ..addExpression(
              declareVar(
                'remoteDataSource',
                type: refer(remoteDataSourceName),
                late: true,
              ),
            )
            ..addExpression(
              declareVar('repoImpl', type: refer(repoImplName), late: true),
            )
            ..addExpression(
              refer('setUp').call([
                Method((methodBuilder) {
                  methodBuilder.body = Block((body) {
                    body
                      ..addExpression(
                        refer('remoteDataSource').assign(
                          refer('Mock$remoteDataSourceName').newInstance([]),
                        ),
                      )
                      ..addExpression(
                        refer('repoImpl').assign(
                          refer(repoImplName).newInstance(
                            [refer('remoteDataSource')],
                          ),
                        ),
                      );
                  });
                }).closure,
              ]),
            )
            ..addExpression(
              declareConst('serverFailure').assign(
                refer('ServerFailure').newInstance(
                  [],
                  {
                    'message': literalString('Something went wrong'),
                    'statusCode': literalNum(500),
                  },
                ),
              ),
            );
          for (final method in visitor.methods) {
            body.addExpression(
              _generateMethodTest(
                method: method,
                arguments: methodArguments[method.name]!,
              ),
            );
          }
        });
    });
  }

  Class _generateMockDataSourceClass({
    required String remoteDataSourceName,
  }) {
    return Class((classBuilder) {
      classBuilder
        ..name = 'Mock$remoteDataSourceName'
        ..extend = refer('Mock')
        ..implements.add(refer(remoteDataSourceName));
    });
  }

  Expression _generateMethodTest({
    required IFunction method,
    required TestMethodArgs arguments,
  }) {
    return refer('group').call([
      literalString(method.name),
      Method((methodBuilder) {
        methodBuilder.body = Block((block) {
          // Generate test data
          _generateTestData(method: method).forEach(block.addExpression);

          // Generate success test
          block
            ..addExpression(
              _generateSuccessTest(method: method, arguments: arguments),
            )
            // Generate failure test
            ..addExpression(
              _generateFailureTest(method: method, arguments: arguments),
            );
        });
      }).closure,
    ]);
  }

  List<Expression> _generateTestData({
    required IFunction method,
  }) {
    final expressions = <Expression>[];
    final returnType = method.rawType.rightType;
    final resultRef = returnType.fallbackValue(
      useConstForCollections: false,
      useModelForCustomType: true,
      skipIfNullable: false,
    );

    if (returnType is! VoidType) {
      final resultDeclaration = returnType.isConst
          ? declareConst('tResult')
          : declareFinal('tResult');
      expressions.add(resultDeclaration.assign(resultRef));
    }

    if (method.hasParams) {
      for (final param in method.params!) {
        final variableName = 't${param.name.pascalCase}';
        final variableRef = param.rawType.isConst
            ? declareConst(variableName)
            : declareFinal(variableName);
        expressions.add(
          variableRef.assign(
            param.fallbackValue(
              useConstForCollections: false,
              skipIfNullable: false,
              useModelForCustomType: true,
            ),
          ),
        );
      }
    }

    final paramsToRegister = method.params?.where((param) {
      return param.type.isCustomType &&
          !param.rawType.isDartCoreList &&
          !param.rawType.isEnum;
    });

    if (paramsToRegister?.isNotEmpty ?? false) {
      expressions.add(
        refer('setUp').call([
          Method((methodBuilder) {
            methodBuilder.body = Block((body) {
              for (final param in paramsToRegister!) {
                body.addExpression(
                  refer(
                    'registerFallbackValue',
                  ).call([refer('t${param.name.pascalCase}')]),
                );
              }
            });
          }).closure,
        ]),
      );
    }
    return expressions;
  }

  Expression _generateSuccessTest({
    required IFunction method,
    required TestMethodArgs arguments,
  }) {
    final isStream = method.rawType.isDartAsyncStream;
    final methodName = method.name;
    final returnType = method.rawType.rightType;
    final isVoid = returnType is VoidType;

    final (
      :positionalWhenArguments,
      :positionalVerifyArguments,
      :namedWhenArguments,
      :namedVerifyArguments,
    ) = arguments;

    String testDescription;
    if (isVoid && !isStream) {
      testDescription =
          'should complete successfully when call to remote '
          'source is successful';
    } else {
      final action = isStream ? 'emit' : 'return';
      // Generates: should return [Right<User>] when call to...
      testDescription =
          'should $action [Right<${returnType.displayString()}>] when call to '
          'remote source is successful';
    }

    return refer('test').call([
      Utils.smartString(testDescription),
      Method((methodBuilder) {
        if (!isStream) {
          methodBuilder.modifier = MethodModifier.async;
        }

        final useLambdas = Utils.shouldUseLambdaBody(
          methodHasParams: method.hasParams,
          namedArgumentsLength: namedWhenArguments.length,
          positionalWhenArgumentsLength: positionalWhenArguments.length,
        );

        methodBuilder.body = Block((body) {
          // ARRANGE
          body
            ..addExpression(
              _generateWhenExpression(
                method: method,
                useLambdas: useLambdas,
                positionalWhenArguments: positionalWhenArguments,
                namedWhenArguments: namedWhenArguments,
                isFailure: false,
              ),
            )
            // ACT
            ..addExpression(
              _generateActExpression(
                methodName: methodName,
                isStream: isStream,
                positionalArgs: positionalVerifyArguments,
                namedArgs: namedVerifyArguments,
              ),
            )
            // ASSERT
            ..addExpression(
              _generateExpectExpression(
                method: method,
                isFailure: false,
              ),
            );

          // VERIFY
          _generateVerificationExpressions(
            useLambdas: useLambdas,
            methodName: methodName,
            positionalVerifyArguments: positionalVerifyArguments,
            namedVerifyArguments: namedVerifyArguments,
          ).forEach(body.addExpression);
        });
      }).closure,
    ]);
  }

  Expression _generateFailureTest({
    required IFunction method,
    required TestMethodArgs arguments,
  }) {
    final isStream = method.rawType.isDartAsyncStream;
    final methodName = method.name;

    final (
      :positionalWhenArguments,
      :positionalVerifyArguments,
      :namedWhenArguments,
      :namedVerifyArguments,
    ) = arguments;
    final testDescription =
        'should ${isStream ? 'emit' : 'return'} [Left<Failure>] when call to '
        'remote source is unsuccessful';

    return refer('test').call([
      Utils.smartString(testDescription),
      Method((methodBuilder) {
        if (!isStream) {
          methodBuilder.modifier = MethodModifier.async;
        }

        final useLambdas = Utils.shouldUseLambdaBody(
          methodHasParams: method.hasParams,
          namedArgumentsLength: namedWhenArguments.length,
          positionalWhenArgumentsLength: positionalWhenArguments.length,
        );

        methodBuilder.body = Block((body) {
          // ARRANGE
          body
            ..addExpression(
              _generateWhenExpression(
                method: method,
                useLambdas: useLambdas,
                positionalWhenArguments: positionalWhenArguments,
                namedWhenArguments: namedWhenArguments,
                isFailure: true,
              ),
            )
            // ACT
            ..addExpression(
              _generateActExpression(
                methodName: method.name,
                isStream: isStream,
                positionalArgs: arguments.positionalVerifyArguments,
                namedArgs: arguments.namedVerifyArguments,
              ),
            )
            // ASSERT
            ..addExpression(
              _generateExpectExpression(
                method: method,
                isFailure: true,
              ),
            );
          _generateVerificationExpressions(
            useLambdas: useLambdas,
            methodName: methodName,
            positionalVerifyArguments: positionalVerifyArguments,
            namedVerifyArguments: namedVerifyArguments,
          ).forEach(body.addExpression);
        });
      }).closure,
    ]);
  }

  List<Expression> _generateVerificationExpressions({
    required bool useLambdas,
    required String methodName,
    required List<Expression> positionalVerifyArguments,
    required Map<String, Expression> namedVerifyArguments,
  }) {
    return [
      refer('verify')
          .call([
            Method((methodBuilder) {
              final body = refer('remoteDataSource')
                  .property(methodName)
                  .call(
                    positionalVerifyArguments,
                    namedVerifyArguments,
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
      refer(
        'verifyNoMoreInteractions',
      ).call([refer('remoteDataSource')]),
    ];
  }

  Expression _generateWhenExpression({
    required IFunction method,
    required List<Expression> positionalWhenArguments,
    required Map<String, Expression> namedWhenArguments,
    required bool useLambdas,
    required bool isFailure,
  }) {
    final methodName = method.name;
    final isStream = method.rawType.isDartAsyncStream;
    final isVoid = method.rawType.rightType is VoidType;

    // the Exception (Failure Payload)
    final exceptionRef = refer('ServerException').newInstance(
      [],
      {
        'message': refer('serverFailure').property('message'),
        'statusCode': refer('serverFailure').property('statusCode'),
      },
    );

    // the Success Payload
    Expression successResponse;
    if (isStream) {
      // Stream.value(tResult)
      successResponse = refer(
        'Stream',
      ).property('value').call([if (isVoid) literalNull else refer('tResult')]);
    } else if (isVoid) {
      // Future.value() -> Void callback
      successResponse = refer('Future').property('value').call([]);
    } else {
      // Just tResult
      successResponse = refer('tResult');
    }

    // Determine 'then' Strategy
    // Streams ALWAYS use thenAnswer (to return a Stream object).
    // Futures use thenAnswer (Success) or thenThrow (Failure).
    final thenMethod = (isStream || !isFailure) ? 'thenAnswer' : 'thenThrow';

    Expression thenArgument;

    if (isFailure) {
      if (isStream) {
        // Failure Stream: (_) => Stream.error(ex)
        thenArgument = Method((methodBuilder) {
          methodBuilder
            ..requiredParameters.add(
              Parameter((param) => param.name = '_'),
            )
            ..body = refer(
              'Stream',
            ).property('error').call([exceptionRef]).returned.statement;
        }).closure;
      } else {
        // Failure Future: exceptionRef (passed to thenThrow)
        thenArgument = exceptionRef;
      }
    } else {
      // Success (Stream or Future)
      // (_) async => successResponse
      thenArgument = Method(
        (methodBuilder) => methodBuilder
          ..requiredParameters.add(Parameter((param) => param.name = '_'))
          ..modifier = isStream ? null : MethodModifier.async
          ..lambda = true
          ..body = successResponse.code,
      ).closure;
    }

    return refer('when')
        .call([
          Method((methodBuilder) {
            final body = refer('remoteDataSource')
                .property(methodName)
                .call(
                  positionalWhenArguments,
                  namedWhenArguments,
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
        .property(thenMethod)
        .call([thenArgument]);
  }

  Expression _generateActExpression({
    required String methodName,
    required bool isStream,
    required List<Expression> positionalArgs,
    required Map<String, Expression> namedArgs,
  }) {
    // repoImpl.method(args)
    final callExpression = refer('repoImpl')
        .property(methodName)
        .call(
          positionalArgs,
          namedArgs,
        );

    final resultName = isStream ? 'stream' : 'result';

    // final result = await callExpr;
    return declareFinal(resultName).assign(
      isStream ? callExpression : callExpression.awaited,
    );
  }

  Expression _generateExpectExpression({
    required IFunction method,
    required bool isFailure,
  }) {
    final isStream = method.rawType.isDartAsyncStream;
    final returnType = method.rawType.rightType;
    final isVoid = returnType is VoidType;

    final resultRef = refer(isStream ? 'stream' : 'result');

    final containerSymbol = isFailure ? 'Left' : 'Right';

    // Generic Types: <Failure, ReturnType>
    final typeRef = TypeReference(
      (ref) => ref
        ..symbol = containerSymbol
        ..types.addAll([
          refer('Failure'),
          refer(returnType.displayString()),
        ]),
    );

    Expression expectedValue;

    if (isFailure) {
      // Left(serverFailure)
      expectedValue = typeRef.constInstance([refer('serverFailure')]);
    } else if (isVoid) {
      // const Right(null)
      expectedValue = typeRef.constInstance([literalNull]);
    } else {
      // Right(tResult)
      expectedValue = typeRef.newInstance([refer('tResult')]);
    }

    // Wrap in Matcher (equals vs emits)
    final matcher = isStream
        ? refer('emits').call([expectedValue])
        : refer('equals').call([expectedValue]);

    // expect(result, matcher);
    return refer('expect').call([resultRef, matcher]);
  }
}

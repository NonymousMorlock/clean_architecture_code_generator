import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/class_builder_extensions.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/core/extensions/repo_visitor_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/src/generators/state_name_generator.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating an Adapter (Cubit/Bloc classes) from repository
/// annotations.
///
/// Processes classes annotated with `@AdapterGenAnnotation` and generates
/// corresponding Adapter classes for the interface adapter.
class AdapterGenerator extends GeneratorForAnnotation<AdapterGenAnnotation> {
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

    // Debug: Write to log file
    try {
      File('/tmp/adapter_gen_debug.log').writeAsStringSync(
        'isMultiFileEnabled: ${writer.isMultiFileEnabled}\n'
        'config.multiFileOutput.enabled: ${config.multiFileOutput.enabled}\n'
        'inputPath: ${buildStep.inputId.path}\n',
        mode: FileMode.append,
      );
    } on Exception catch (_) {
      // Ignore
    }

    final className = visitor.className;

    final featureName = writer.extractFeatureName(repoName: visitor.className);

    if (writer.isMultiFileEnabled && featureName != null) {
      return _generateMultiFile(
        visitor: visitor,
        writer: writer,
        featureName: featureName.pascalCase,
      );
    }

    if (writer.isMultiFileEnabled && featureName == null) {
      stdout.writeln(
        '[AdapterGenerator] Feature name is null, falling back to '
        'default generation',
      );
    }

    // Default behavior: generate to .g.dart

    final fallBackFeatureName = className
        .replaceAll('CubitTBG', '')
        .replaceAll('Cubit', '')
        .replaceAll('AdapterTBG', '')
        .replaceAll('Adapter', '')
        .replaceAll('RepoTBG', '')
        .replaceAll('Repo', '');

    final feature = featureName?.camelCase ?? fallBackFeatureName;

    // Generate Adapter
    final adapterClass = _interfaceAdapter(
      visitor: visitor,
      className: feature.pascalCase,
    );

    // Generate States
    final adapterStateClass = _interfaceAdapterState(
      visitor: visitor,
      className: feature.pascalCase,
    );

    return writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..comments.addAll([
            '// **************************************************************************',
            '// AdapterGenerator - ${feature.pascalCase} Adapter',
            '// **************************************************************************',
          ])
          ..body.addAll([
            adapterClass,
            Library((stateLibrary) {
              stateLibrary
                ..comments.addAll([
                  '// **************************************************************************',
                  '// StateGenerator - ${feature.pascalCase} States',
                  '// **************************************************************************',
                ])
                ..body.addAll(adapterStateClass);
            }),
          ]);
      }),
    );
  }

  String _generateMultiFile({
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
    required String featureName,
  }) {
    // Generate adapter file
    final adapter = _interfaceAdapter(
      visitor: visitor,
      className: featureName,
    );

    final adapterState = _interfaceAdapterState(
      visitor: visitor,
      className: featureName,
    );

    final adapterPath = writer.getInterfaceAdapterPath(featureName.snakeCase);
    final statePath = writer.getInterfaceAdapterStatePath(
      featureName.snakeCase,
    );

    // Generate complete file with imports
    final (:imports, :importComments) = writer
        .generateSmartInterfaceAdapterImports(
          candidates: visitor.discoverRequiredEntities(),
          methods: visitor.methods,
          featureName: featureName,
        );

    final completeAdapterFile = writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..body.add(adapter)
          ..comments.addAll(importComments)
          ..directives.addAll(imports.map(Directive.import))
          ..directives.add(
            Directive.part('${featureName.snakeCase}_state.dart'),
          );
      }),
    );

    final completeStateFile = writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..body.addAll(adapterState)
          ..directives.add(
            Directive.partOf('${featureName.snakeCase}_adapter.dart'),
          );
      }),
    );

    // Write to actual files
    try {
      writer
        ..writeToFile(adapterPath, completeAdapterFile)
        ..writeToFile(statePath, completeStateFile);

      // Return minimal marker for .g.dart file
      return '// Adapter written to: $adapterPath\n// State written to: '
          '$statePath';
    } on Exception catch (e, s) {
      stderr
        ..writeln('[AdapterGenerator] ERROR: Could not write adapter files: $e')
        ..writeln('[AdapterGenerator] Stack trace: $s');
      return '// ERROR: Could not write adapter files: $e';
    }
  }

  Class _interfaceAdapter({
    required RepoVisitor visitor,
    required String className,
  }) {
    final adapterName = '${className}Adapter';
    final stateName = '${className}State';

    return Class((classBuilder) {
      final streamMethods = <IFunction>[];
      classBuilder
        ..name = adapterName
        ..extend = TypeReference((ref) {
          ref
            ..symbol = 'Cubit'
            ..types.add(Reference(stateName));
        })
        ..constructors.add(
          Constructor((constructor) {
            constructor
              ..optionalParameters.addAll(
                visitor.methods.map((method) {
                  final usecaseName = method.name.pascalCase;
                  final paramName = method.name.camelCase;
                  return Parameter((param) {
                    param
                      ..name = paramName
                      ..type = Reference(usecaseName)
                      ..named = true
                      ..required = true;
                  });
                }),
              )
              ..initializers.addAll([
                ...visitor.methods.map((method) {
                  final paramName = method.name.camelCase;
                  return refer('_$paramName').assign(Reference(paramName)).code;
                }),
                refer(
                  'super',
                ).call([refer('${className}Initial').constInstance([])]).code,
              ]);
          }),
        )
        ..fields.addAll(
          visitor.methods.map((method) {
            final usecaseName = method.name.pascalCase;
            final paramName = method.name.camelCase;
            if (method.rawType.isDartAsyncStream) streamMethods.add(method);
            return Field((field) {
              field
                ..name = '_$paramName'
                ..type = Reference(usecaseName)
                ..modifier = FieldModifier.final$;
            });
          }),
        )
        ..fields.addAll(
          streamMethods.map((method) {
            return Field((field) {
              field
                ..name = '_${method.name.camelCase}Subscription'
                ..type = TypeReference((ref) {
                  ref
                    ..symbol = 'StreamSubscription'
                    ..types.add(Reference(method.returnType.innerType))
                    ..isNullable = true;
                });
            });
          }),
        )
        ..methods.addAll(
          visitor.methods.map((method) {
            return _generateAdapterMethod(
              method: method,
              featureName: className,
            );
          }),
        )
        ..methods.addAll([
          Method((methodBuilder) {
            methodBuilder
              ..name = 'emit'
              ..returns = const Reference('void')
              ..annotations.add(const Reference('override'))
              ..requiredParameters.add(
                Parameter((param) {
                  param
                    ..name = 'state'
                    ..type = Reference(stateName);
                }),
              )
              ..body = Block((block) {
                block
                  ..statements.add(const Code('if (isClosed) return;'))
                  ..addExpression(
                    refer(
                      'super',
                    ).property('emit').call([const Reference('state')]),
                  );
              });
          }),
          if (streamMethods.isNotEmpty)
            Method((methodBuilder) {
              methodBuilder
                ..name = 'close'
                ..returns = TypeReference((ref) {
                  ref
                    ..symbol = 'Future'
                    ..types.add(const Reference('void'));
                })
                ..annotations.add(const Reference('override'))
                ..modifier = MethodModifier.async
                ..body = Block((block) {
                  for (final method in streamMethods) {
                    block.addExpression(
                      refer(
                        '_${method.name.camelCase}Subscription',
                      ).nullSafeProperty('cancel').call([]).awaited,
                    );
                  }
                  block.addExpression(
                    refer('super').property('close').call([]).returned,
                  );
                });
            }),
        ]);
    });
  }

  Method _generateAdapterMethod({
    required IFunction method,
    required String featureName,
  }) {
    final methodName = method.name;
    final usecasePrivateName = '_${methodName.camelCase}';
    final returnType = method.returnType.rightType;
    final isStream = method.rawType.isDartAsyncStream;
    var streamName = methodName;
    if (!streamName.toLowerCase().trim().endsWith('stream')) {
      streamName += 'Stream';
    }
    return Method((methodBuilder) {
      methodBuilder
        ..name = isStream ? streamName : method.name
        ..returns = TypeReference((ref) {
          ref.symbol = 'Future';
          ref.types.add(const Reference('void'));
        })
        ..modifier = MethodModifier.async
        ..optionalParameters.addAll(
          method.params?.map((param) {
                return Parameter((paramBuilder) {
                  paramBuilder
                    ..name = param.name
                    ..type = TypeReference((ref) {
                      ref
                        ..symbol = param.type.trim().replaceAll('?', '')
                        ..isNullable = param.isNullable;
                    })
                    ..named = true
                    ..required = !param.isNullable;
                });
              }) ??
              [],
        )
        ..body = Block((body) {
          final paramsClassName = '${methodName.pascalCase}Params';
          final needsCustomParams =
              method.params != null && method.params!.length > 1;
          var resultAssignment = refer(usecasePrivateName).call(
            [
              if (!needsCustomParams && method.hasParams)
                refer(method.params!.first.name)
              else if (needsCustomParams)
                refer(paramsClassName).newInstance(
                  [],
                  {
                    for (final param in method.params!)
                      param.name: refer(param.name),
                  },
                ),
            ],
          );

          final errorClassName = '${featureName}Error';
          if (!isStream) {
            resultAssignment = resultAssignment.awaited;
            body
              ..addExpression(
                refer(
                  'emit',
                ).call([refer('${featureName}Loading').constInstance([])]),
              )
              ..addExpression(declareFinal('result').assign(resultAssignment))
              ..addExpression(
                _foldResult(
                  errorClassName: errorClassName,
                  methodName: methodName,
                  featureName: featureName,
                  returnType: returnType,
                  rawReturnType: method.rawType,
                ),
              );
          } else {
            final streamSubscriptionName = '${usecasePrivateName}Subscription';
            body
              ..addExpression(
                refer(
                  streamSubscriptionName,
                ).nullSafeProperty('cancel').call([]).awaited,
              )
              ..addExpression(declareFinal('stream').assign(resultAssignment))
              ..addExpression(
                refer(streamSubscriptionName).assign(
                  refer('stream')
                      .property('listen')
                      .call(
                        [
                          Method((onDataMethod) {
                            onDataMethod
                              ..requiredParameters.add(
                                Parameter((param) => param.name = 'result'),
                              )
                              ..body = _foldResult(
                                errorClassName: errorClassName,
                                methodName: methodName,
                                featureName: featureName,
                                returnType: returnType,
                                rawReturnType: method.rawType,
                              ).statement;
                          }).closure,
                        ],
                        {
                          'onError': Method((onErrorMethod) {
                            onErrorMethod
                              ..requiredParameters.addAll([
                                Parameter((param) {
                                  param
                                    ..name = 'error'
                                    ..type = const Reference('Object');
                                }),
                                Parameter((param) {
                                  param
                                    ..name = 'stackTrace'
                                    ..type = const Reference('StackTrace');
                                }),
                              ])
                              ..body = refer('emit').call([
                                refer(errorClassName).constInstance([], {
                                  'message': literalString(
                                    'Something went wrong',
                                  ),
                                  'title': literalString('Unknown Error'),
                                }),
                              ]).statement;
                          }).closure,
                          'cancelOnError': literalFalse,
                        },
                      ),
                ),
              );
          }
        });
    });
  }

  Expression _foldResult({
    required String errorClassName,
    required String methodName,
    required String featureName,
    required String returnType,
    required DartType rawReturnType,
  }) {
    return refer('result').property('fold').call([
      Method((failureMethod) {
        failureMethod
          ..requiredParameters.add(
            Parameter((param) => param.name = 'failure'),
          )
          ..lambda = true
          ..body = refer('emit').call([
            refer(
              errorClassName,
            ).newInstanceNamed('fromFailure', [refer('failure')]),
          ]).code;
      }).closure,
      Method((successMethod) {
        // Generate success state based on method name and return type
        final successState = StateNameGenerator.generate(
          methodName: methodName,
          featureName: featureName,
          returnType: returnType,
        );

        final successType = rawReturnType.successType;
        final isVoid = successType is VoidType;
        final successStateRef = refer(successState);
        final paramName = _getSuccessParamName(returnType: successType);
        successMethod
          ..requiredParameters.add(
            Parameter((param) => param.name = paramName ?? '_'),
          )
          ..lambda = true
          ..body = refer('emit').call([
            if (isVoid)
              successStateRef.constInstance([])
            else
              successStateRef.newInstance([], {paramName!: refer(paramName)}),
          ]).code;
      }).closure,
    ]);
  }

  List<Class> _interfaceAdapterState({
    required RepoVisitor visitor,
    required String className,
  }) {
    final stateName = '${className}State';

    final stateClasses = [
      _generateBaseState(stateName: stateName),
      _generateChildState(
        stateName: '${className}Initial',
        parentClassName: stateName,
      ),
      _generateChildState(
        stateName: '${className}Loading',
        parentClassName: stateName,
      ),
    ];

    // Generate success states based on methods
    final successStates = <String>{};

    for (final method in visitor.methods) {
      final returnType = method.returnType.rightType;
      final successState = StateNameGenerator.generate(
        methodName: method.name,
        featureName: className,
        returnType: returnType,
      );

      if (!successStates.contains(successState)) {
        successStates.add(successState);
        stateClasses.add(
          _generateSuccessStateClass(
            successStateName: successState,
            returnType: method.rawType.successType,
            baseStateName: stateName,
          ),
        );
      }
    }

    stateClasses.add(
      Class((classBuilder) {
        classBuilder
          ..name = '${className}Error'
          ..extend = Reference(stateName)
          ..modifier = ClassModifier.final$
          ..constructors.addAll([
            Constructor((constructor) {
              constructor
                ..constant = true
                ..optionalParameters.addAll(
                  List.generate(2, (index) {
                    return Parameter((param) {
                      param
                        ..name = switch (index) {
                          0 => 'message',
                          _ => 'title',
                        }
                        ..toThis = true
                        ..named = true
                        ..required = true;
                    });
                  }),
                );
            }),
            Constructor((constructor) {
              constructor
                ..name = 'fromFailure'
                ..requiredParameters.add(
                  Parameter((param) {
                    param
                      ..name = 'failure'
                      ..type = const Reference('Failure');
                  }),
                )
                ..initializers.add(
                  refer('this').call([], {
                    'message': refer('failure').property('message'),
                    'title': literalString(r'Error ${failure.statusCode}'),
                  }).code,
                );
            }),
          ])
          ..fields.addAll(
            List.generate(2, (index) {
              return Field((field) {
                field
                  ..modifier = FieldModifier.final$
                  ..type = TypeReference((ref) {
                    ref
                      ..symbol = 'String'
                      ..isNullable = index == 1;
                  })
                  ..name = switch (index) {
                    0 => 'message',
                    _ => 'title',
                  };
              });
            }),
          )
          ..addEquatableProps(
            body: literalList([refer('message'), refer('title')]).code,
          );
      }),
    );
    return stateClasses;
  }

  Class _generateChildState({
    required String stateName,
    required String parentClassName,
  }) {
    return Class((classBuilder) {
      classBuilder
        ..name = stateName
        ..extend = Reference(parentClassName)
        ..modifier = ClassModifier.final$
        ..constructors.add(
          Constructor((constructor) => constructor.constant = true),
        );
    });
  }

  Class _generateBaseState({required String stateName}) {
    return Class((classBuilder) {
      classBuilder
        ..name = stateName
        ..extend = const Reference('Equatable')
        ..sealed = true
        ..constructors.add(
          Constructor((constructor) => constructor.constant = true),
        )
        ..addEquatableProps(params: []);
    });
  }

  Class _generateSuccessStateClass({
    required String successStateName,
    required DartType returnType,
    required String baseStateName,
  }) {
    return Class((classBuilder) {
      final hasReturnData = returnType is! VoidType;
      final paramName = _getSuccessParamName(
        returnType: returnType,
      );
      classBuilder
        ..name = successStateName
        ..extend = Reference(baseStateName)
        ..modifier = ClassModifier.final$
        ..constructors.add(
          Constructor((constructor) {
            if (hasReturnData) {
              constructor.optionalParameters.add(
                Parameter((param) {
                  param
                    ..name = paramName!
                    ..toThis = true
                    ..named = true
                    ..required =
                        returnType.nullabilitySuffix == NullabilitySuffix.none;
                }),
              );
            }

            constructor.constant = true;
          }),
        );
      if (hasReturnData) {
        final body = returnType.successType.isDartCoreList
            ? refer(paramName!)
            : literalList([refer(paramName!)]);
        classBuilder
          ..fields.add(
            Field((field) {
              field
                ..name = paramName
                ..type = TypeReference((ref) {
                  ref
                    ..symbol = returnType.displayString(
                      withNullability: false,
                    )
                    ..isNullable =
                        returnType.nullabilitySuffix ==
                        NullabilitySuffix.question;
                })
                ..modifier = FieldModifier.final$;
            }),
          )
          ..addEquatableProps(body: body.code);
      }
    });
  }

  String? _getSuccessParamName({required DartType returnType}) {
    if (returnType is! VoidType) {
      var paramName = 'data';
      if (returnType.hasCustomType) {
        paramName = returnType.deepestType
            .displayString(withNullability: false)
            .camelCase;
        if (returnType.isDartCoreList) {
          paramName = '${paramName}List';
        }
      }
      return paramName;
    }
    return null;
  }
}

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/core/extensions/model_visitor_extensions.dart';
import 'package:generators/core/extensions/param_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating model classes from entity annotations.
///
/// Processes classes annotated with `@ModelGenAnnotation` and generates
/// corresponding model classes in the data layer with JSON serialization.
class ModelGenerator extends GeneratorForAnnotation<ModelGenAnnotation> {
  // When handling the `toMap` and `fromMap`, you'll notice I've used the
  // configs for `DateTime` in the `toMap` but not using in the `fromMap`.
  //
  // The reason for this is "Postel's Law" (The Robustness Principle).
  //
  // "Be conservative in what you do, be liberal in what you accept
  // from others."
  //
  // So, based on this rule:
  //
  // `toMap` (Writing/Sending): I MUST obey the config.
  // The backend expects a specific format (e.g., specific timestamp format),
  // so our generator must be strict here.
  //
  // `fromMap` (Reading/Receiving): I should IGNORE the config and use the
  // Helper.
  //
  // Why? Even if the user thinks the API sends `timestamp_ms`,
  // the API might change to ISO strings tomorrow, or send an int
  // for one record and a double for another.
  //
  // Our helper `_parseDateTime` handles all of these cases automatically. It
  // is strictly superior to a rigid config-based parser because
  // it auto-adapts at runtime.
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target non-classes.',
      );
    }

    final visitor = ModelVisitor();

    final constructor = element.unnamedConstructor;

    if (constructor != null) {
      visitor.visitConstructorElement(constructor);
    } else {
      stderr.writeln(
        '[ModelGenerator] Error: No default constructor found for '
        '${element.name}',
      );
      return '// Error: No default constructor found for ${element.name}';
    }

    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

    var ignoreMultiFileCheck = false;

    if (config.multiFileOutput.enabled && !config.featureScaffolding.enabled) {
      // throw InvalidGenerationSourceError(
      //   'Multi-file output requires feature scaffolding to '
      //   'be enabled in the configuration, if you are going to be '
      //   'generating models and entities',
      // );
      stderr.writeln(
        '[ModelGenerator] Multi-file output requires feature scaffolding to '
        'be enabled in the configuration. Ignoring multi-file setting.',
      );
      ignoreMultiFileCheck = true;
    }

    final writer = FeatureFileWriter(config: config, buildStep: buildStep);

    // Normalize the class name: UserTBG -> User
    final normalisedName = visitor.className
        .replaceAll('TBG', '')
        .replaceAll('Model', '');

    final associatedFeatureName = writer.getAssociatedFeatureNameForEntity(
      entityName: normalisedName,
    );

    if (associatedFeatureName == null) {
      stderr.writeln(
        '[ModelGenerator] Warning: No associated feature found for entity '
        '$normalisedName. Generated entity will not be placed in a '
        'feature-specific directory.',
      );
      ignoreMultiFileCheck = true;
    }

    if (writer.isMultiFileEnabled && !ignoreMultiFileCheck) {
      return _generateMultiFile(
        visitor: visitor,
        config: config,
        writer: writer,
        normalisedName: normalisedName,
        associatedFeatureName: associatedFeatureName!,
      );
    }

    final modelClass = _generateModelClass(
      visitor: visitor,
      entityName: normalisedName,
      config: config,
    );

    return writer.resolveGeneratedCode(
      library: Library((library) => library.body.add(modelClass)),
    );
  }

  String _generateMultiFile({
    required ModelVisitor visitor,
    required FeatureFileWriter writer,
    required GeneratorConfig config,
    required String normalisedName,
    required String associatedFeatureName,
  }) {
    final (:imports, :importComments) = writer.generateSmartModelImports(
      candidates: visitor.discoverRequiredEntities(),
      featureName: associatedFeatureName,
      parentEntityName: normalisedName,
    );

    final modelClass = _generateModelClass(
      visitor: visitor,
      entityName: normalisedName,
      config: config,
    );

    final modelPath = writer.getModelPath(
      featureName: associatedFeatureName,
      entityName: normalisedName,
    );

    final completeFile = writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..body.add(modelClass)
          ..comments.addAll(importComments)
          ..directives.addAll(imports.map(Directive.import));
      }),
    );

    try {
      writer.writeToFile(modelPath, completeFile);

      return '// Model class written to: $modelPath\n';
    } on Exception catch (e, s) {
      stderr
        ..writeln(
          '[ModelGenerator] ERROR: Could not write model files: $e',
        )
        ..writeln('[ModelGenerator] Stack trace: $s');
      return '// Error: Could not write model class to file: $e\n';
    }
  }

  /// Generates the model class and all its methods.
  ///
  /// Creates the main constructor, empty constructor, and all
  /// serialization/deserialization methods.
  Class _generateModelClass({
    required GeneratorConfig config,
    required ModelVisitor visitor,
    required String entityName,
  }) {
    final modelClassName = '${entityName}Model';

    return Class((classBuilder) {
      classBuilder
        ..name = modelClassName
        ..extend = refer(entityName)
        ..constructors.addAll([
          Constructor((constructor) {
            constructor
              ..constant = true
              ..optionalParameters.addAll(
                visitor.params.map((param) {
                  return Parameter((paramBuilder) {
                    paramBuilder
                      ..name = param.name.camelCase
                      ..named = true
                      ..required = !param.isNullable && !param.hasDefaultValue
                      ..defaultTo = param.hasDefaultValue
                          ? Code(param.defaultValueCode!)
                          : null
                      ..toSuper = true;
                  });
                }),
              );
          }),
          Constructor((constructor) {
            constructor
              ..name = 'empty'
              ..constant = visitor.params.every(
                (param) => param.rawType.isConst || param.isNullable,
              )
              ..initializers.add(
                refer('this').call(
                  [],
                  {
                    for (final param in visitor.params)
                      param.name.camelCase: param.fallbackValue(
                        useModelForCustomType: true,
                      ),
                  },
                ).code,
              );
          }),
          fromJson(className: modelClassName),
          fromMap(visitor: visitor),
        ])
        ..methods.addAll([
          copyWith(visitor: visitor, className: modelClassName),
          toMap(visitor: visitor, config: config, entityName: entityName),
          toJson(),
          if (visitor.params.any((param) => param.rawType.isDateTime))
            _generateDateTimeParsingHelper(),
          if (visitor.params.any((param) => param.rawType.isDartCoreInt))
            _generateIntParsingHelper(),
          if (visitor.params.any((param) => param.rawType.isDartCoreDouble))
            _generateDoubleParsingHelper(),
        ]);
    });
  }

  /// Generates the fromMap factory constructor.
  ///
  /// Creates a factory that deserializes a model from a Map,
  /// handling various data types including DateTime and numeric conversions.
  Constructor fromMap({required ModelVisitor visitor}) {
    return Constructor((constructor) {
      // TODO(Documentation): Add this note somewhere for the user to see.
      // I'm using the param.name as it is. So, if the user's API is
      // returning snake case keys, they have to declare the properties using
      // snake case in the annotated class
      final entries = <String, Expression>{};
      final dynamicListTypeRef = TypeReference((ref) {
        ref
          ..symbol = 'List'
          ..types.add(const Reference('dynamic'));
      });
      for (final param in visitor.params) {
        final type = param.rawType;
        final argumentName = param.name.camelCase;
        final valueReference = refer('map').index(literalString(param.name));

        Expression value;

        if (type.hasCustomType) {
          final customTypeReference = refer(type.deepestType.modelize);
          if (param.rawType.isDartCoreList) {
            value =
                TypeReference((ref) {
                      ref
                        ..symbol = 'List'
                        ..types.add(const Reference('DataMap'));
                    })
                    .newInstanceNamed('from', [
                      valueReference.asA(dynamicListTypeRef),
                    ])
                    .property('map')
                    .call([customTypeReference.property('fromMap')])
                    .property('toList')
                    .call([]);
            if (param.isNullable) {
              value = valueReference
                  .notEqualTo(literalNull)
                  .conditional(value, literalNull);
            }
          } else {
            value = customTypeReference.newInstanceNamed('fromMap', [
              valueReference.asA(const Reference('DataMap')),
            ]);
            if (param.isNullable) {
              value = valueReference
                  .notEqualTo(literalNull)
                  .conditional(value, literalNull);
            }
          }
        } else if (param.rawType.isDartCoreList) {
          value = refer(
            type.displayString(withNullability: false),
          ).newInstanceNamed('from', [valueReference.asA(dynamicListTypeRef)]);

          if (param.isNullable) {
            value = valueReference
                .notEqualTo(literalNull)
                .conditional(value, literalNull);
          }
        } else if (param.rawType.isDartCoreInt) {
          value = refer('_parseInt').call([valueReference]);

          if (param.isNullable) {
            value = valueReference
                .notEqualTo(literalNull)
                .conditional(value, literalNull);
          }
        } else if (param.rawType.isDartCoreDouble) {
          value = refer('_parseDouble').call([valueReference]);

          if (param.isNullable) {
            value = valueReference
                .notEqualTo(literalNull)
                .conditional(value, literalNull);
          }
        } else if (type.isDateTime) {
          value = refer('_parseDateTime').call([valueReference]);
          if (param.isNullable) {
            value = valueReference
                .notEqualTo(literalNull)
                .conditional(value, literalNull);
          }
        } else if (type.isEnum) {
          value = refer(
            type.displayString(withNullability: false),
          ).property('fromString').call([valueReference.asA(refer('String'))]);

          if (param.isNullable) {
            value = valueReference
                .notEqualTo(literalNull)
                .conditional(value, literalNull);
          }
        } else {
          value = valueReference.asA(refer(type.displayString()));
        }
        entries[argumentName] = value;
      }
      constructor
        ..name = 'fromMap'
        ..requiredParameters.add(
          Parameter((param) {
            param
              ..name = 'map'
              ..type = const Reference('DataMap');
          }),
        )
        ..initializers.add(refer('this').call([], entries).code);
    });
  }

  /// Generates the fromJson factory constructor.
  ///
  /// Creates a factory that deserializes a model from a JSON string.
  Constructor fromJson({required String className}) {
    return Constructor((constructor) {
      constructor
        ..factory = true
        ..name = 'fromJson'
        ..requiredParameters.add(
          Parameter(
            (param) {
              param
                ..name = 'source'
                ..type = refer('String');
            },
          ),
        )
        ..lambda = true
        ..body = refer(className).newInstanceNamed('fromMap', [
          refer('jsonDecode').call([refer('source')]).asA(refer('DataMap')),
        ]).code;
    });
  }

  /// Generates the toMap method.
  ///
  /// Creates a method that serializes the model to a Map,
  /// properly handling DateTime conversion to ISO 8601 strings.
  Method toMap({
    required ModelVisitor visitor,
    required GeneratorConfig config,
    required String entityName,
  }) {
    return Method((methodBuilder) {
      methodBuilder
        ..name = 'toMap'
        ..returns = const Reference('DataMap')
        ..body = Block((body) {
          final entries = <String, Expression>{};
          for (final param in visitor.params) {
            final key = param.name;
            Expression valueReference = refer(param.name.camelCase);

            if (param.rawType.hasCustomType) {
              if (param.rawType.isDartCoreList) {
                valueReference = param.isNullable
                    ? valueReference.nullSafeProperty('map')
                    : valueReference.property('map');

                valueReference = valueReference
                    .call([
                      Method((methodBuilder) {
                        methodBuilder
                          ..lambda = true
                          ..requiredParameters.add(
                            Parameter((param) => param.name = 'e'),
                          )
                          ..body = refer('e')
                              .asA(refer(param.rawType.deepestType.modelize))
                              .property('toMap')
                              .call([])
                              .code;
                      }).closure,
                    ])
                    .property('toList')
                    .call([]);
              } else {
                valueReference = valueReference.asA(
                  TypeReference((ref) {
                    ref
                      ..symbol = param.rawType.deepestType.modelize
                      ..isNullable = param.isNullable;
                  }),
                );
                valueReference = param.isNullable
                    ? valueReference.nullSafeProperty('toMap')
                    : valueReference.property('toMap');
                valueReference = valueReference.call([]);
              }
            } else if (param.rawType.isEnum) {
              valueReference = param.isNullable
                  ? valueReference.nullSafeProperty('value')
                  : valueReference.property('value');
            } else if (param.rawType.isDateTime) {
              // 1. Resolve the Config Format

              // Lookup logic: Specific Model -> Default
              final format = _resolveDateFormat(
                config: config,
                entityName: entityName.snakeCase,
                fieldName: param.name.snakeCase,
              );

              // 2. Generate Expression based on Format
              switch (format) {
                case 'timestamp_ms':
                  // Generates: created_at: value?.millisecondsSinceEpoch
                  valueReference = param.isNullable
                      ? valueReference.nullSafeProperty(
                          'millisecondsSinceEpoch',
                        )
                      : valueReference.property('millisecondsSinceEpoch');

                case 'timestamp_s':
                  // Generates: created_at: value == null ? null : value.millisecondsSinceEpoch ~/ 1000
                  final msAccess = valueReference.property(
                    'millisecondsSinceEpoch',
                  );
                  final division = msAccess.operatorIntDivide(literalNum(1000));

                  if (param.isNullable) {
                    // We cannot divide null, so we must use a conditional check
                    valueReference = valueReference
                        .equalTo(literalNull)
                        .conditional(literalNull, division);
                  } else {
                    valueReference = division;
                  }

                case 'iso_string':
                default:
                  // Generates: created_at: value?.toIso8601String()
                  valueReference = param.isNullable
                      ? valueReference.nullSafeProperty('toIso8601String')
                      : valueReference.property('toIso8601String');

                  valueReference = valueReference.call([]);
              }
            }

            entries[key] = valueReference;
          }
          body.addExpression(
            literalMap(entries, refer('String'), refer('dynamic')).returned,
          );
        });
    });
  }

  /// Generates the toJson method.
  ///
  /// Creates a method that serializes the model to a JSON string.
  Method toJson() {
    return Method((method) {
      method
        ..name = 'toJson'
        ..returns = const Reference('String')
        ..lambda = true
        ..body = refer('jsonEncode').call([refer('toMap').call([])]).code;
    });
  }

  /// Generates the copyWith method.
  ///
  /// Creates a method that returns a new instance with updated values,
  /// following the immutable pattern.
  Method copyWith({
    required ModelVisitor visitor,
    required String className,
  }) {
    return Method((methodBuilder) {
      methodBuilder
        ..name = 'copyWith'
        ..returns = refer(className)
        ..optionalParameters.addAll(
          visitor.params.map((param) {
            return Parameter((paramBuilder) {
              paramBuilder
                ..name = param.name.camelCase
                ..named = true
                ..type = TypeReference((ref) {
                  ref
                    ..symbol = param.rawType.hasCustomType
                        ? param.rawType.modelize
                        : param.rawType.displayString(withNullability: false)
                    ..isNullable = true;
                });
            });
          }),
        )
        ..body = Block((body) {
          body.addExpression(
            refer(
              className,
            ).newInstance([], {
              for (final param in visitor.params)
                param.name.camelCase: refer(
                  param.name.camelCase,
                ).ifNullThen(refer('this').property(param.name.camelCase)),
            }).returned,
          );
        });
    });
  }

  String _resolveDateFormat({
    required GeneratorConfig config,
    required String entityName,
    required String fieldName,
  }) {
    // We normalize names to match the YAML structure (snake_case)
    final modelKey = entityName.snakeCase;
    final fieldKey = fieldName.snakeCase;

    return config
            .modelTestConfig
            .modelConfigs[modelKey]
            ?.fieldTypes[fieldKey] ??
        config.modelTestConfig.defaults.datetimeFormat;
  }

  // While "Don't Repeat Yourself" (DRY) is a golden rule for human-written
  // code, I'll still put this helper in the model files themselves.
  // WHY?
  // If I generate a user_model.dart, I want it to "just work." If I move
  // the logic to a shared core/utils/date_parser.dart, then I create a hard
  // dependency.
  //
  // Scenario: A user deletes the core folder to regenerate it,
  // or moves the Model file to another package.
  //
  // Result: The Model breaks because it can't find the utility.
  //
  //
  // Also, by embedding the helper, the file is portable. It doesn't rely on
  // the user having run the `Core` generator successfully.
  //
  //
  // I also do not have to worry about bloat. The Dart compiler is smart. If
  // you have 50 private _parseDateTime methods in 50 files, the compiler
  // will inline/optimize them efficiently.
  // The file size increase is negligible compared to the stability benefits.
  Method _generateDateTimeParsingHelper() {
    return Method((method) {
      method
        ..docs.add(
          '/// Helper method to parse DateTime from various API '
          'formats',
        )
        ..name = '_parseDateTime'
        ..requiredParameters.add(
          Parameter((param) {
            param
              ..name = 'value'
              ..type = refer('dynamic');
          }),
        )
        ..returns = refer('DateTime')
        ..static = true
        ..body = Block((body) {
          body
            // String
            ..statements.add(const Code('if (value is String) {'))
            ..addExpression(
              refer(
                'DateTime',
              ).property('parse').call([refer('value')]).returned,
            )
            // Int
            ..statements.add(const Code('} else if (value is int) {'))
            ..statements.add(
              const Code('// Handle timestamp (milliseconds or seconds)'),
            )
            ..addExpression(
              refer(
                    'value',
                  )
                  .greaterThan(literalNum(1000000000000))
                  .conditional(
                    refer('DateTime').newInstanceNamed(
                      'fromMillisecondsSinceEpoch',
                      [refer('value')],
                    ),
                    refer(
                      'DateTime',
                    ).newInstanceNamed('fromMillisecondsSinceEpoch', [
                      refer('value').operatorMultiply(literalNum(1000)),
                    ]),
                  )
                  .returned,
            )
            // double
            ..statements.add(const Code('} else if (value is double) {'))
            ..addExpression(
              refer('DateTime').newInstanceNamed('fromMillisecondsSinceEpoch', [
                refer('value').property('toInt').call([]),
              ]).returned,
            )
            ..statements.add(const Code('} else {'))
            ..addExpression(
              refer('FormatException').newInstance([
                const CodeExpression(
                  Code(r"'Invalid DateTime format: $value'"),
                ),
              ]).thrown,
            )
            ..statements.add(const Code('}'));
        });
    });
  }

  Method _generateIntParsingHelper() {
    return Method((method) {
      method
        ..docs.add('/// Helper method to parse int from various API formats')
        ..name = '_parseInt'
        ..requiredParameters.add(
          Parameter(
            (param) => param
              ..name = 'value'
              ..type = refer('dynamic'),
          ),
        )
        ..returns = refer('int')
        ..static = true
        ..body = Block((body) {
          body
            ..statements.add(const Code('if (value is int) {'))
            ..addExpression(refer('value').returned)
            ..statements.add(const Code('} else if (value is double) {'))
            ..addExpression(refer('value').property('toInt').call([]).returned)
            ..statements.add(const Code('} else if (value is String) {'))
            ..addExpression(
              declareFinal('result').assign(
                refer('int').property('tryParse').call([refer('value')]),
              ),
            )
            ..statements.add(const Code('if (result != null) {'))
            ..addExpression(refer('result').returned)
            ..statements.add(const Code('}'))
            ..addExpression(
              refer('Exception').newInstance([
                literalString(
                  r'Invalid int string: $value',
                ),
              ]).thrown,
            )
            ..statements.add(const Code('} else {'))
            ..addExpression(
              refer('Exception').newInstance([
                literalString('Invalid type for int field'),
              ]).thrown,
            )
            ..statements.add(const Code('}'));
        });
    });
  }

  Method _generateDoubleParsingHelper() {
    return Method((method) {
      method
        ..docs.add('/// Helper method to parse double from various API formats')
        ..name = '_parseDouble'
        ..requiredParameters.add(
          Parameter(
            (param) => param
              ..name = 'value'
              ..type = refer('dynamic'),
          ),
        )
        ..returns = refer('double')
        ..static = true
        ..body = Block((body) {
          body
            ..statements.add(const Code('if (value is double) {'))
            ..addExpression(refer('value').returned)
            ..statements.add(const Code('} else if (value is int) {'))
            ..addExpression(
              refer('value').property('toDouble').call([]).returned,
            )
            ..statements.add(const Code('} else if (value is String) {'))
            // Handles "1.5" and "1" (via double.parse)
            ..addExpression(
              declareFinal('result').assign(
                refer('double').property('tryParse').call([refer('value')]),
              ),
            )
            ..statements.add(const Code('if (result != null) {'))
            ..addExpression(refer('result').returned)
            ..statements.add(const Code('}'))
            ..addExpression(
              refer('Exception').newInstance([
                literalString(
                  r'Invalid int string: $value',
                ),
              ]).thrown,
            )
            ..statements.add(const Code('} else {'))
            ..addExpression(
              refer('Exception').newInstance([
                literalString('Invalid type for double field'),
              ]).thrown,
            )
            ..statements.add(const Code('}'));
        });
    });
  }
}

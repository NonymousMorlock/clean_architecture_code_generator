import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/core/extensions/iterable_extensions.dart';
import 'package:generators/core/extensions/model_visitor_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/src/models/param.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating test files for model classes.
///
/// Processes classes annotated with `@ModelTestGenAnnotation` and generates
/// comprehensive test files for model classes.
class ModelTestGenerator
    extends GeneratorForAnnotation<ModelTestGenAnnotation> {
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
        '[ModelTestGenerator] Multi-file output requires '
        'feature scaffolding to be enabled in the configuration. '
        'Ignoring multi-file setting.',
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
        '[ModelTestGenerator] Warning: No associated feature found for entity '
        '$normalisedName. Generated entity will not be placed in a '
        'feature-specific directory.',
      );
      ignoreMultiFileCheck = true;
    }
    if (writer.isMultiFileEnabled && !ignoreMultiFileCheck) {
      return _generateMultiFile(
        writer: writer,
        config: config,
        normalisedName: normalisedName,
        visitor: visitor,
        featureName: associatedFeatureName!,
      );
    }
    final fixture = _generateFixtureFile(
      config: config,
      className: normalisedName,
      visitor: visitor,
    );

    final completeFixtureFile = const JsonEncoder.withIndent(
      '  ',
    ).convert(fixture);

    final fixtureReader = _generateFixtureReader();

    final modelTest = _generateModelTest(
      config: config,
      visitor: visitor,
      className: normalisedName,
    );

    return writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..comments.addAll([
            '// **************************************************************************',
            '// Fixture Generator - $normalisedName Fixture',
            '// **************************************************************************',
            '',
            '// GENERATED FIXTURE FILE (YAML Config-Aware)',
            '// Create this file at: test/fixtures/${normalisedName.snakeCase}.json',
            '// Content generated based on YAML configuration:',
          ])
          ..body.addAll([
            Code('/*\n$completeFixtureFile\n*/\n'),
            Library((library) {
              library
                ..comments.addAll([
                  '// **************************************************************************',
                  '// Fixture Reader',
                  '// **************************************************************************',
                  '',
                  '// Helper function to read fixture files for tests.',
                  'Create this file at: test/fixtures/fixture_reader.dart',
                ])
                ..body.add(fixtureReader);
            }),
            modelTest,
          ]);
      }),
    );
  }

  String _generateMultiFile({
    required GeneratorConfig config,
    required String normalisedName,
    required ModelVisitor visitor,
    required FeatureFileWriter writer,
    required String featureName,
  }) {
    final results = <String>[];
    final fixturePath = writer.getModelFixturePath(entityName: normalisedName);
    // Generate fixture file
    final fixture = _generateFixtureFile(
      config: config,
      className: normalisedName,
      visitor: visitor,
    );

    final completeFixtureFile = const JsonEncoder.withIndent(
      '  ',
    ).convert(fixture);

    try {
      writer.writeToFile(fixturePath, completeFixtureFile);
      results.add('// $normalisedName fixture written to: $fixturePath\n');
    } on Exception catch (e, s) {
      stderr
        ..writeln(
          '[ModelTestGenerator] ERROR: Could not write fixture file: $e',
        )
        ..writeln('[ModelTestGenerator] Stack trace: $s');
      results.add('// Error: Could not write fixture file: $e\n');
    }

    if (!writer.fixtureReaderExists()) {
      final fixtureReaderPath = writer.getFixtureReaderPath();
      final fixtureReader = _generateFixtureReader();

      final completeFixtureReaderFile = writer.resolveGeneratedCode(
        library: Library((library) {
          library
            ..directives.add(Directive.import('dart:io'))
            ..body.add(fixtureReader);
        }),
      );

      try {
        writer.writeToFile(fixtureReaderPath, completeFixtureReaderFile);
        results.add(
          '// Fixture reader written to: $fixtureReaderPath\n',
        );
      } on Exception catch (e, s) {
        stderr
          ..writeln(
            '[ModelTestGenerator] ERROR: Could not write '
            'fixture reader file: $e',
          )
          ..writeln('[ModelTestGenerator] Stack trace: $s');
        results.add('// Error: Could not write fixture reader file: $e\n');
      }
    }

    final modelTestPath = writer.getModelTestPath(
      featureName: featureName,
      entityName: normalisedName,
    );

    final (:imports, :importComments) = writer.generateSmartModelTestImports(
      candidates: visitor.discoverRequiredEntities(),
      featureName: featureName,
      entityName: normalisedName,
    );

    final modelTest = _generateModelTest(
      config: config,
      visitor: visitor,
      className: normalisedName,
    );

    final completeTestFile = writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..directives.addAll(imports.map(Directive.import))
          ..comments.addAll(importComments)
          ..body.add(modelTest);
      }),
    );

    try {
      writer.writeToFile(modelTestPath, completeTestFile);

      results.add(
        '// ${normalisedName}Model test written to: $modelTestPath\n',
      );
    } on Exception catch (e, s) {
      stderr
        ..writeln(
          '[ModelTestGenerator] ERROR: Could not write model test file: $e',
        )
        ..writeln('[ModelTestGenerator] Stack trace: $s');
      results.add('// Error: Could not write model test to file: $e\n');
    }

    // Return markers for the .g.dart file
    return '${results.join('\n')}\n';
  }

  Method _generateModelTest({
    required GeneratorConfig config,
    required String className,
    required ModelVisitor visitor,
  }) {
    final modelClassName = '${className}Model';

    return Method((methodBuilder) {
      methodBuilder
        ..name = 'main'
        ..returns = const Reference('void')
        ..body = Block((block) {
          _generateTestSetup(
            className: className,
            modelClassName: modelClassName,
            visitor: visitor,
            config: config,
          ).forEach(block.addExpression);
          block
            ..addExpression(
              _generateEntitySubclassTest(
                modelClassName: modelClassName,
                entityClassName: className,
              ),
            )
            ..addExpression(_generateFromMapTest(modelClassName))
            ..addExpression(_generateToMapTest(modelClassName))
            ..addExpression(
              _generateCopyWithTest(
                modelClassName: modelClassName,
                visitor: visitor,
              ),
            )
            ..addExpression(
              _generateFromJsonTest(modelClassName: modelClassName),
            )
            ..addExpression(
              _generateToJsonTest(modelClassName: modelClassName),
            );
        });
    });
  }

  List<Expression> _generateTestSetup({
    required String className,
    required String modelClassName,
    required ModelVisitor visitor,
    required GeneratorConfig config,
  }) {
    final fixtureFileName = '${className.snakeCase}.json';
    final testModelName = 't$modelClassName';

    final arrangement = [
      // late final UserModel tUserModel;
      declareFinal(testModelName, late: true, type: refer(modelClassName)),

      // late final DataMap tMap;
      declareFinal('tMap', late: true, type: refer('DataMap')),
    ];

    final setUp = refer('setUpAll').call([
      Method((methodBuilder) {
        methodBuilder.body = Block((body) {
          // final fixtureString = fixture('file.json');
          body
            ..addExpression(
              declareFinal(
                'fixtureString',
              ).assign(refer('fixture').call([literalString(fixtureFileName)])),
            )
            // tMap = jsonDecode(fixtureString) as DataMap;
            ..addExpression(
              refer('tMap').assign(
                refer(
                  'jsonDecode',
                ).call([refer('fixtureString')]).asA(refer('DataMap')),
              ),
            );

          // Hydrate Custom Types in tMap
          // Since the fixture generator skips Custom Types
          // (returns CustomType sentinel), we must inject valid data into
          // tMap so .fromMap() doesn't crash.
          for (final param in visitor.params) {
            if (param.rawType.hasCustomType &&
                !param.rawType.isDartCoreList &&
                !param.rawType.isEnum) {
              final fieldName = param.name;
              final subModelName = param.rawType.modelize;

              // tMap['field'] = SubModel.empty().toMap();
              body.addExpression(
                refer('tMap')
                    .index(literalString(fieldName))
                    .assign(
                      refer(subModelName)
                          .newInstanceNamed('empty', [])
                          .property('toMap')
                          .call([]),
                    ),
              );
            }
          }

          // Instantiate tModel using empty().copyWith()
          // We only override DateTimes to match the static fixture date.
          final copyWithArgs = <String, Expression>{};

          for (final param in visitor.params) {
            if (param.rawType.isDateTime && !param.isNullable) {
              final configuredType = _getConfiguredFieldType(
                config: config,
                className: className,
                fieldName: param.name,
                fieldType: param.type,
              );

              copyWithArgs[param.name.camelCase] = _getDateTimeExpression(
                configuredType,
              );
            }
          }

          // tModel = UserModel.empty().copyWith(...);
          body.addExpression(
            refer(testModelName).assign(
              refer(modelClassName)
                  .newInstanceNamed('empty', [])
                  .property('copyWith')
                  .call([], copyWithArgs),
            ),
          );
        });
      }).closure,
    ]);
    return [...arrangement, setUp];
  }

  /// Helper to generate the exact DateTime object expected by the fixture
  Expression _getDateTimeExpression(String configuredType) {
    // ISO String (Default)
    if (configuredType.isEmpty || configuredType == 'iso_string') {
      return refer('DateTime').property('parse').call([
        literalString('2024-01-01T00:00:00.000Z'),
      ]);
    }

    // Timestamps (Milliseconds)
    if (configuredType == 'timestamp_ms') {
      return refer('DateTime')
          .newInstanceNamed(
            'fromMillisecondsSinceEpoch',
            [literalNum(1704067200000)],
          )
          .property('toUtc')
          .call([]);
    }

    // Timestamps (Seconds)
    if (configuredType == 'timestamp_s') {
      // Note: fromMillisecondsSinceEpoch takes ms, so we pass the ms value
      // derived from the seconds (1704067200 * 1000)
      return refer('DateTime')
          .newInstanceNamed(
            'fromMillisecondsSinceEpoch',
            [literalNum(1704067200000)],
          )
          .property('toUtc')
          .call([]);
    }

    // Fallback
    return refer('DateTime').property('parse').call([
      literalString('2024-01-01T00:00:00.000Z'),
    ]);
  }

  Expression _generateEntitySubclassTest({
    required String modelClassName,
    required String entityClassName,
  }) {
    final testModelName = 't$modelClassName';

    return refer('test').call([
      literalString('should be a subclass of $entityClassName entity'),
      Method((methodBuilder) {
        methodBuilder.body = Block((body) {
          body.addExpression(
            refer('expect').call([
              refer(testModelName),
              refer('isA').call([], {}, [refer(entityClassName)]),
            ]),
          );
        });
      }).closure,
    ]);
  }

  Expression _generateFromMapTest(String modelClassName) {
    final testModelName = 't$modelClassName';

    return refer('group').call([
      literalString('fromMap'),
      Method((methodBuilder) {
        methodBuilder.body = Block((block) {
          block.addExpression(
            refer('test').call([
              literalString(
                'should return a valid model when the map is valid',
              ),
              Method((methodBuilder) {
                methodBuilder.body = Block((body) {
                  body
                    ..addExpression(
                      declareFinal('result').assign(
                        refer(
                          modelClassName,
                        ).property('fromMap').call([refer('tMap')]),
                      ),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('result'),
                        refer('isA').call([], {}, [refer(modelClassName)]),
                      ]),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('result'),
                        refer('equals').call([refer(testModelName)]),
                      ]),
                    );
                });
              }).closure,
            ]),
          );
        });
      }).closure,
    ]);
  }

  Expression _generateToMapTest(String modelClassName) {
    final testModelName = 't$modelClassName';

    return refer('group').call([
      literalString('toMap'),
      Method((methodBuilder) {
        methodBuilder.body = Block((block) {
          block.addExpression(
            refer('test').call([
              literalString(
                'should return a JSON map containing the proper data',
              ),
              Method((methodBuilder) {
                methodBuilder.body = Block((body) {
                  body
                    ..addExpression(
                      declareFinal('result').assign(
                        refer(testModelName).property('toMap').call([]),
                      ),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('result'),
                        refer('isA').call([], {}, [refer('DataMap')]),
                      ]),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('result'),
                        refer('equals').call([refer('tMap')]),
                      ]),
                    );
                });
              }).closure,
            ]),
          );
        });
      }).closure,
    ]);
  }

  Expression _generateCopyWithTest({
    required String modelClassName,
    required ModelVisitor visitor,
  }) {
    final testModelName = 't$modelClassName';

    return refer('group').call([
      literalString('copyWith'),
      Method((groupBuilder) {
        groupBuilder.body = Block((block) {
          // 1. SELECT A CANDIDATE FIELD
          // We prioritize non-nullable primitives because they are the safest
          // to generate "different" values for without complex logic.
          Param? candidate;
          Expression? valueToUpdate;

          // Priority 1: String
          candidate = visitor.params.firstWhereOrNull(
            (param) => param.rawType.isDartCoreString,
          );
          if (candidate != null) {
            valueToUpdate = literalString(
              'Updated ${candidate.name.camelCase}',
            );
          }

          // Priority 2: Int (If no String)
          if (candidate == null) {
            candidate = visitor.params.firstWhereOrNull(
              (param) => param.rawType.isDartCoreInt,
            );
            if (candidate != null) {
              // Setup usually uses '1', so we use '2'
              valueToUpdate = literalNum(2);
            }
          }

          // Priority 3: Bool (If no String/Int)
          if (candidate == null) {
            candidate = visitor.params.firstWhereOrNull(
              (param) => param.rawType.isDartCoreBool,
            );
            if (candidate != null) {
              // Setup usually uses 'true', so we use 'false'
              valueToUpdate = literalFalse;
            }
          }

          // Priority 4: Double
          if (candidate == null) {
            candidate = visitor.params.firstWhereOrNull(
              (param) => param.rawType.isDartCoreDouble,
            );
            if (candidate != null) {
              // Setup usually uses '1.0', so we use '2.0'
              valueToUpdate = literalNum(2.0);
            }
          }

          // ONLY generate the update test if we found a safe candidate.
          // If the model only contains List<CustomType>, generating a valid
          // copyWith test automatically is too risky/complex for a generic tool.
          if (candidate != null && valueToUpdate != null) {
            block.addExpression(
              refer('test').call([
                literalString(
                  'should return a copy of the model with updated fields',
                ),
                Method((methodBuilder) {
                  methodBuilder.body = Block((body) {
                    body
                      ..addExpression(
                        declareFinal('result').assign(
                          refer(testModelName).property('copyWith').call([], {
                            candidate!.name.camelCase: valueToUpdate!,
                          }),
                        ),
                      )
                      ..addExpression(
                        refer('expect').call([
                          refer('result'),
                          refer('isA').call([], {}, [refer(modelClassName)]),
                        ]),
                      )
                      ..addExpression(
                        refer('expect').call([
                          refer('result').property(candidate.name.camelCase),
                          refer('equals').call([valueToUpdate]),
                        ]),
                      );

                    // Assert Other Fields Unchanged
                    // Find one other field that isn't the candidate
                    final otherField = visitor.params.firstWhereOrNull(
                      (param) => param.name != candidate!.name,
                    );

                    if (otherField != null) {
                      body.statements.add(
                        const Code('// Ensure other fields remain unchanged'),
                      );
                      body.addExpression(
                        refer('expect').call([
                          refer('result').property(otherField.name.camelCase),
                          refer('equals').call([
                            refer(
                              testModelName,
                            ).property(otherField.name.camelCase),
                          ]),
                        ]),
                      );
                    }
                  });
                }).closure,
              ]),
            );
          }

          // 2. TEST NO ARGS (Identity/Equality Check)
          // This is always safe to generate
          block.addExpression(
            refer('test').call([
              literalString(
                'should return the same instance when no '
                'parameters are provided',
              ),
              Method((methodBuilder) {
                methodBuilder.body = Block((body) {
                  body
                    ..addExpression(
                      declareFinal('result').assign(
                        refer(testModelName).property('copyWith').call([]),
                      ),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('result'),
                        refer('equals').call([refer(testModelName)]),
                      ]),
                    );
                });
              }).closure,
            ]),
          );
        });
      }).closure,
    ]);
  }

  Expression _generateFromJsonTest({required String modelClassName}) {
    final testModelName = 't$modelClassName';

    return refer('group').call([
      literalString('fromJson'),
      Method((methodBuilder) {
        methodBuilder.body = Block((block) {
          block.addExpression(
            refer('test').call([
              literalString(
                'should return a valid model when the JSON string is valid',
              ),
              Method((testBuilder) {
                testBuilder.body = Block((body) {
                  body
                    ..addExpression(
                      declareFinal('jsonString').assign(
                        refer('jsonEncode').call([refer('tMap')]),
                      ),
                    )
                    ..addExpression(
                      declareFinal('result').assign(
                        refer(
                          modelClassName,
                        ).property('fromJson').call([refer('jsonString')]),
                      ),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('result'),
                        refer('isA').call([], {}, [refer(modelClassName)]),
                      ]),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('result'),
                        refer('equals').call([refer(testModelName)]),
                      ]),
                    );
                });
              }).closure,
            ]),
          );
        });
      }).closure,
    ]);
  }

  Expression _generateToJsonTest({required String modelClassName}) {
    final testModelName = 't$modelClassName';
    return refer('group').call([
      literalString('toJson'),
      Method((methodBuilder) {
        methodBuilder.body = Block((block) {
          block.addExpression(
            refer('test').call([
              literalString(
                'should return a JSON string containing the proper data',
              ),
              Method((methodBuilder) {
                methodBuilder.body = Block((body) {
                  // 1. Act: Call toJson()
                  body
                    ..addExpression(
                      declareFinal('result').assign(
                        refer(testModelName).property('toJson').call([]),
                      ),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('result'),
                        refer('isA').call([], {}, [refer('String')]),
                      ]),
                    )
                    ..statements.add(
                      const Code(
                        '// Parse both to compare as maps (order-independent)',
                      ),
                    )
                    ..addExpression(
                      declareFinal('resultMap').assign(
                        refer(
                          'jsonDecode',
                        ).call([refer('result')]).asA(refer('DataMap')),
                      ),
                    )
                    ..addExpression(
                      refer('expect').call([
                        refer('resultMap'),
                        refer('equals').call([refer('tMap')]),
                      ]),
                    );
                });
              }).closure,
            ]),
          );
        });
      }).closure,
    ]);
  }

  Method _generateFixtureReader() {
    return Method((methodBuilder) {
      methodBuilder
        ..name = 'fixture'
        ..returns = const Reference('String')
        ..requiredParameters.add(
          Parameter((paramBuilder) {
            paramBuilder
              ..name = 'name'
              ..type = const Reference('String');
          }),
        )
        ..lambda = true
        ..body = refer('File')
            .call([literalString(r'test/fixtures/$name')])
            .property('readAsStringSync')
            .call([])
            .code;
    });
  }

  DataMap _generateFixtureFile({
    required String className,
    required ModelVisitor visitor,
    required GeneratorConfig config,
  }) {
    final fixture = <String, dynamic>{};

    for (final param in visitor.params) {
      final value = _getJsonValueForConfiguredType(
        field: param,
        configuredType: _getConfiguredFieldType(
          config: config,
          className: className,
          fieldName: param.name,
          fieldType: param.type,
        ),
      );
      if (value is CustomType) continue;
      if (value is UnsupportedJsonType) {
        stderr.writeln(
          '[ModelTestGenerator] Warning: Unsupported type for field '
          '${param.name} (${param.type}). Skipping in fixture generation.',
        );
        continue;
      }
      fixture[param.name] = value;
    }

    return fixture;
  }

  String _getConfiguredFieldType({
    required GeneratorConfig config,
    required String className,
    required String fieldName,
    required String fieldType,
  }) {
    // Use the actual YAML configuration
    return config.modelTestConfig.getFieldType(
      modelName: className,
      fieldName: fieldName,
      dartType: fieldType,
    );
  }

  /// Get JSON value based on configured type from YAML
  /// for fields that can have multiple formats.
  ///
  /// If no special configuration, falls back to default value.
  Object? _getJsonValueForConfiguredType({
    required Param field,
    required String configuredType,
  }) {
    if (field.isNullable) return null;
    final fieldType = field.rawType;
    // I've intentionally put the collection types first to avoid
    // misclassification (e.g., 'list of strings' should match 'list' first)
    if (fieldType.isDartCoreList ||
        fieldType.isDartCoreSet ||
        fieldType.isDartCoreIterable) {
      return [];
    }
    if (fieldType.isDartCoreMap) {
      return {};
    } else if (fieldType.isDartCoreString) {
      return 'Test String';
    } else if (fieldType.isDartCoreBool) {
      return true;
    } else if (fieldType.isDateTime) {
      return switch (configuredType) {
        // 2024-01-01 in milliseconds
        'timestamp_ms' => 1704067200000,
        // 2024-01-01 in seconds
        'timestamp_s' => 1704067200,
        // includes 'iso_string'
        _ => '2024-01-01T00:00:00.000Z',
      };
    } else if (fieldType.isDartCoreDouble) {
      return switch (configuredType) {
        'int' => 1,
        'string' => '1.0',
        // includes 'double'
        _ => 1.0,
      };
    } else if (fieldType.isDartCoreInt) {
      return switch (configuredType) {
        'string' => '1',
        // includes 'int'
        _ => 1,
      };
    } else if (fieldType.isEnum) {
      return 'unknown';
    } else if (fieldType.hasCustomType) {
      // TODO(Documentation): Mention in the docs that custom types will be
      //  skipped in fixture generation, but will be injected in the actual test

      // For custom types, I'll inject it in the actual test by calling
      // CustomType.empty().toMap() and adding that to the fixture, since I
      // can't possibly get access to the custom type here.
      return CustomType();
    }
    return UnsupportedJsonType();
  }
}

/// A placeholder class to represent custom types in fixture generation.
class CustomType {}

/// A placeholder class to represent unsupported types in fixture generation.
class UnsupportedJsonType {}

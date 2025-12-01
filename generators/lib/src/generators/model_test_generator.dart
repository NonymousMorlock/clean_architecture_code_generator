// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
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
    final visitor = ModelVisitor();
    element.visitChildren(visitor);

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

    String? associatedFeatureName;

    // Normalize the class name: UserTBG -> User -> user
    final normalisedName = visitor.className
        .replaceAll('TBG', '')
        .replaceAll('Model', '');

    for (final featureEntry in config.featureScaffolding.features.entries) {
      final featureName = featureEntry.key;
      final definition = featureEntry.value;
      if (definition.entities.contains(normalisedName.toLowerCase())) {
        associatedFeatureName = featureName;
        break;
      }
    }

    if (associatedFeatureName == null) {
      stderr.writeln(
        '[ModelTestGenerator] Warning: No associated feature found for entity '
        '$normalisedName. Generated entity will not be placed in a '
        'feature-specific directory.',
      );
      ignoreMultiFileCheck = true;
    }
    final writer = FeatureFileWriter(config, buildStep);

    if (writer.isMultiFileEnabled && !ignoreMultiFileCheck) {
      return _generateMultiFile(
        writer: writer,
        config: config,
        normalisedName: normalisedName,
        visitor: visitor,
        featureName: associatedFeatureName!,
      );
    }

    final buffer = StringBuffer();
    _generateModelTest(
      config: config,
      buffer: buffer,
      visitor: visitor,
      className: normalisedName,
    );

    // Generate fixture file
    _generateFixtureFile(
      config: config,
      buffer: buffer,
      className: normalisedName,
      visitor: visitor,
    );

    return buffer.toString();
  }

  String _generateMultiFile({
    required GeneratorConfig config,
    required String normalisedName,
    required ModelVisitor visitor,
    required FeatureFileWriter writer,
    required String featureName,
  }) {
    final testBuffer = StringBuffer();
    final modelTestPath = writer.getModelTestPath(
      featureName: featureName,
      entityName: normalisedName,
    );
    _generateModelTest(
      config: config,
      visitor: visitor,
      buffer: testBuffer,
      className: normalisedName,
    );

    final fixtureBuffer = StringBuffer();
    final fixturePath = writer.getModelFixturePath(entityName: normalisedName);
    // Generate fixture file
    _generateFixtureFile(
      config: config,
      className: normalisedName,
      buffer: fixtureBuffer,
      visitor: visitor,
    );

    final results = <String>[];

    try {
      writer.writeToFile(modelTestPath, testBuffer.toString());

      stdout.writeln('[ModelTestGenerator] Successfully wrote files');
      results.add(
        '// ${normalisedName}Model test written to: $modelTestPath\n',
      );

      writer.writeToFile(fixturePath, fixtureBuffer.toString());
      stdout.writeln('[ModelTestGenerator] Successfully wrote files');
      results.add('// $normalisedName fixture written to: $fixturePath\n');
    } on Exception catch (e, s) {
      stderr
        ..writeln(
          '[ModelTestGenerator] ERROR: Could not write model files: $e',
        )
        ..writeln('[ModelTestGenerator] Stack trace: $s');
      results.add('// Error: Could not write model class to file: $e\n');
    }

    // Return markers for the .g.dart file
    return '${results.join('\n')}\n';
  }

  void _generateModelTest({
    required GeneratorConfig config,
    required String className,
    required StringBuffer buffer,
    required ModelVisitor visitor,
  }) {
    final modelClassName = '${className}Model';
    final entityClassName = className;

    // Configuration is loaded in individual methods as needed

    // Generate imports
    _generateImports(config: config, buffer: buffer, className: className);

    // Generate main test function
    buffer.writeln('void main() {');

    // Generate test model using fixture-based approach
    _generateTestModel(
      config: config,
      buffer: buffer,
      className: className,
      modelClassName: modelClassName,
      entityClassName: entityClassName,
      visitor: visitor,
    );

    // Generate tests
    _generateEntitySubclassTest(buffer, modelClassName, entityClassName);
    _generateFromMapTest(buffer, modelClassName);
    _generateToMapTest(buffer, modelClassName);
    _generateCopyWithTest(buffer, modelClassName, visitor);
    _generateFromJsonTest(buffer, modelClassName);
    _generateToJsonTest(buffer, modelClassName);

    buffer.writeln('}');
  }

  void _generateImports({
    required StringBuffer buffer,
    required String className,
    required GeneratorConfig config,
  }) {
    final classSnakeCase = className.snakeCase;

    // Load configuration to get app name
    final appName = config.appName;
    final rootName = config.featureScaffolding.rootName;

    buffer
      ..writeln("import 'dart:convert';")
      ..writeln()
      ..writeln("import 'package:flutter_test/flutter_test.dart';")
      ..writeln()
      ..writeln("import 'package:$appName/core/typedefs.dart';")
      ..writeln(
        "import 'package:$appName/$rootName/$classSnakeCase/data/models/${classSnakeCase}_model.dart';",
      )
      ..writeln(
        "import 'package:$appName/$rootName/$classSnakeCase/domain/entities/$classSnakeCase.dart';",
      )
      ..writeln()
      ..writeln("import '../../../fixtures/fixture_reader.dart';")
      ..writeln();
  }

  void _generateTestModel({
    required GeneratorConfig config,
    required StringBuffer buffer,
    required String className,
    required String modelClassName,
    required String entityClassName,
    required ModelVisitor visitor,
  }) {
    buffer
      ..writeln(
        '  // Test model created from fixture to ensure consistency',
      )
      ..writeln('  late $modelClassName t$modelClassName;')
      ..writeln('  late DataMap tMap;')
      ..writeln()
      ..writeln('  setUpAll(() {')
      ..writeln('    // Load fixture and create model from it')
      ..writeln(
        "    final fixtureString = fixture('${className.snakeCase}.json');",
      )
      ..writeln('    tMap = jsonDecode(fixtureString) as DataMap;')
      ..writeln();

    // Handle special field transformations for fixtures
    _generateFixtureTransformations(
      config: config,
      buffer: buffer,
      visitor: visitor,
    );

    buffer
      ..writeln('    // Create test model from fixture data')
      ..writeln('    t$modelClassName = $modelClassName.fromMap(tMap);')
      ..writeln('  });')
      ..writeln();
  }

  void _generateFixtureTransformations({
    required GeneratorConfig config,
    required StringBuffer buffer,
    required ModelVisitor visitor,
  }) {
    buffer.writeln(
      '    // Transform fixture data to match expected types',
    );

    for (final field in visitor.fields.entries) {
      final fieldName = field.key;
      final fieldType = field.value;
      final configuredType = _getConfiguredFieldType(
        config,
        'className',
        fieldName,
        fieldType,
      );

      if (fieldType.toLowerCase().contains('datetime')) {
        buffer.writeln(
          '    // Handle DateTime field: '
          '$fieldName (configured as: $configuredType)',
        );

        switch (configuredType) {
          case 'timestamp_ms':
          case 'timestamp_s':
            buffer.writeln("    if (tMap['$fieldName'] is String) {");
            buffer.writeln(
              '      // Convert ISO string to timestamp for API consistency',
            );
            buffer.writeln(
              '      final dateTime = '
              "DateTime.parse(tMap['$fieldName'] as String);",
            );
            if (configuredType == 'timestamp_ms') {
              buffer.writeln(
                "      tMap['$fieldName'] = dateTime.millisecondsSinceEpoch;",
              );
            } else {
              buffer.writeln(
                "      tMap['$fieldName'] = "
                'dateTime.millisecondsSinceEpoch ~/ 1000;',
              );
            }
            buffer.writeln('    }');
          case 'iso_string':
          default:
            buffer.writeln("    if (tMap['$fieldName'] is int) {");
            buffer.writeln(
              '      // Convert timestamp to ISO string for API consistency',
            );
            buffer.writeln(
              "      final timestamp = tMap['$fieldName'] as int;",
            );
            buffer.writeln('      final dateTime = timestamp > 1000000000000');
            buffer.writeln(
              '          ? DateTime.fromMillisecondsSinceEpoch(timestamp)',
            );
            buffer.writeln(
              '          : DateTime.fromMillisecondsSinceEpoch(timestamp '
              '* 1000);',
            );
            buffer.writeln(
              "      tMap['$fieldName'] = dateTime.toIso8601String();",
            );
            buffer.writeln('    }');
        }
      } else if (fieldType.toLowerCase().contains('double') &&
          configuredType.isNotEmpty) {
        buffer.writeln(
          '    // Handle double field: $fieldName '
          '(configured as: $configuredType)',
        );
        switch (configuredType) {
          case 'int':
            buffer.writeln("    if (tMap['$fieldName'] is double) {");
            buffer.writeln(
              "      tMap['$fieldName'] = (tMap['$fieldName'] "
              'as double).toInt();',
            );
            buffer.writeln('    }');
          case 'string':
            buffer.writeln("    if (tMap['$fieldName'] is num) {");
            buffer.writeln(
              "      tMap['$fieldName'] = tMap['$fieldName'].toString();",
            );
            buffer.writeln('    }');
          case 'double':
          default:
            buffer.writeln("    if (tMap['$fieldName'] is int) {");
            buffer.writeln(
              "      tMap['$fieldName'] = (tMap['$fieldName'] "
              'as int).toDouble();',
            );
            buffer.writeln('    }');
        }
      } else if (fieldType.toLowerCase().contains('int') &&
          configuredType == 'string') {
        buffer
          ..writeln(
            '    // Handle int field: $fieldName (configured as: string)',
          )
          ..writeln("    if (tMap['$fieldName'] is int) {")
          ..writeln(
            "      tMap['$fieldName'] = tMap['$fieldName'].toString();",
          )
          ..writeln('    }');
      } else if (fieldType.isCustomType &&
          !fieldType.toLowerCase().contains('list')) {
        buffer
          ..writeln(
            '    // Handle custom type field: $fieldName ($fieldType)',
          )
          ..writeln(
            "    tMap['$fieldName'] = "
            '${fieldType}Model.empty().toMap();',
          );
      }
      buffer.writeln();
    }
    buffer.writeln();
  }

  void _generateEntitySubclassTest(
    StringBuffer buffer,
    String modelClassName,
    String entityClassName,
  ) {
    buffer
      ..writeln(
        "  test('should be a subclass of $entityClassName entity', () {",
      )
      ..writeln('    expect(t$modelClassName, isA<$entityClassName>());')
      ..writeln('  });')
      ..writeln();
  }

  void _generateFromMapTest(StringBuffer buffer, String modelClassName) {
    buffer
      ..writeln("  group('fromMap', () {")
      ..writeln('    test(')
      ..writeln(
        "      'should return a valid model when the map is valid',",
      )
      ..writeln('      () {')
      ..writeln('        final result = $modelClassName.fromMap(tMap);')
      ..writeln()
      ..writeln('        expect(result, isA<$modelClassName>());')
      ..writeln('        expect(result, equals(t$modelClassName));')
      ..writeln('      },')
      ..writeln('    );')
      ..writeln()
      ..writeln('    test(')
      ..writeln(
        "      'should handle null values gracefully for optional fields',",
      )
      ..writeln('      () {')
      ..writeln(
        '        final mapWithNulls = Map<String, dynamic>.from(tMap);',
      )
      ..writeln('        // Set optional fields to null')
      ..writeln("        // mapWithNulls['optionalField'] = null;")
      ..writeln()
      ..writeln(
        '        final result = $modelClassName.fromMap(mapWithNulls);',
      )
      ..writeln()
      ..writeln('        expect(result, isA<$modelClassName>());')
      ..writeln('        // Add specific assertions for null handling')
      ..writeln('      },')
      ..writeln('    );')
      ..writeln('  });')
      ..writeln();
  }

  void _generateToMapTest(StringBuffer buffer, String modelClassName) {
    buffer
      ..writeln("  group('toMap', () {")
      ..writeln('    test(')
      ..writeln(
        "      'should return a JSON map containing the proper data',",
      )
      ..writeln('      () {')
      ..writeln('        final result = t$modelClassName.toMap();')
      ..writeln()
      ..writeln('        expect(result, isA<DataMap>());')
      ..writeln(
        '        // Compare key fields to ensure proper serialization',
      )
      ..writeln("        expect(result['id'], t$modelClassName.id);")
      ..writeln('        // Add more field comparisons as needed')
      ..writeln('      },')
      ..writeln('    );')
      ..writeln('  });')
      ..writeln();
  }

  void _generateCopyWithTest(
    StringBuffer buffer,
    String modelClassName,
    ModelVisitor visitor,
  ) {
    buffer.writeln("  group('copyWith', () {");

    // Find a string field for testing
    String? testField;
    String? testFieldType;
    for (final field in visitor.fields.entries) {
      if (field.value.toLowerCase().contains('string')) {
        testField = field.key.camelCase;
        testFieldType = 'String';
        break;
      }
    }

    if (testField == null) {
      // Fallback to first field
      final firstField = visitor.fields.entries.first;
      testField = firstField.key.camelCase;
      testFieldType = firstField.value;
    }

    buffer
      ..writeln('    test(')
      ..writeln(
        "      'should return a copy of the model with updated fields',",
      )
      ..writeln('      () {');

    String testValue;
    if (testFieldType?.toLowerCase().contains('string') ?? false) {
      testValue = "'Updated $testField'";
    } else if (testFieldType?.toLowerCase().contains('int') ?? false) {
      testValue = '999';
    } else if (testFieldType?.toLowerCase().contains('double') ?? false) {
      testValue = '99.9';
    } else if (testFieldType?.toLowerCase().contains('bool') ?? false) {
      testValue = '!t$modelClassName.$testField';
    } else {
      testValue = 'null'; // For complex types
    }

    buffer
      ..writeln(
        '        final result = '
        't$modelClassName.copyWith($testField: $testValue);',
      )
      ..writeln()
      ..writeln('        expect(result, isA<$modelClassName>());')
      ..writeln('        expect(result.$testField, $testValue);')
      ..writeln('        // Ensure other fields remain unchanged');

    // Test that other fields remain the same
    for (final field in visitor.fields.entries) {
      final fieldName = field.key.camelCase;
      if (fieldName != testField) {
        buffer.writeln(
          '        expect(result.$fieldName, t$modelClassName.$fieldName);',
        );
        break; // Just test one other field to keep it concise
      }
    }

    buffer
      ..writeln('      },')
      ..writeln('    );')
      ..writeln()
      ..writeln('    test(')
      ..writeln(
        "      'should return the same instance when no "
        "parameters are provided',",
      )
      ..writeln('      () {')
      ..writeln('        final result = t$modelClassName.copyWith();')
      ..writeln()
      ..writeln('        expect(result, equals(t$modelClassName));')
      ..writeln('      },')
      ..writeln('    );')
      ..writeln('  });')
      ..writeln();
  }

  void _generateFromJsonTest(StringBuffer buffer, String modelClassName) {
    buffer
      ..writeln("  group('fromJson', () {")
      ..writeln('    test(')
      ..writeln(
        "      'should return a valid model when the JSON string is valid',",
      )
      ..writeln('      () {')
      ..writeln('        final jsonString = jsonEncode(tMap);')
      ..writeln(
        '        final result = $modelClassName.fromJson(jsonString);',
      )
      ..writeln()
      ..writeln('        expect(result, isA<$modelClassName>());')
      ..writeln('        expect(result, equals(t$modelClassName));')
      ..writeln('      },')
      ..writeln('    );')
      ..writeln('  });')
      ..writeln();
  }

  void _generateToJsonTest(StringBuffer buffer, String modelClassName) {
    buffer
      ..writeln("  group('toJson', () {")
      ..writeln('    test(')
      ..writeln(
        "      'should return a JSON string containing the proper data',",
      )
      ..writeln('      () {')
      ..writeln('        final result = t$modelClassName.toJson();')
      ..writeln('        final expectedJson = jsonEncode(tMap);')
      ..writeln()
      ..writeln('        expect(result, isA<String>());')
      ..writeln(
        '        // Parse both to compare as maps (order-independent)',
      )
      ..writeln('        final resultMap = jsonDecode(result) as DataMap;')
      ..writeln(
        '        final expectedMap = jsonDecode(expectedJson) as DataMap;',
      )
      ..writeln('        expect(resultMap, equals(expectedMap));')
      ..writeln('      },')
      ..writeln('    );')
      ..writeln('  });')
      ..writeln();
  }

  void _generateFixtureComments({
    required String className,
    required StringBuffer buffer,
    required GeneratorConfig config,
  }) {
    if (config.multiFileOutput.enabled) return;
    buffer
      ..writeln()
      ..writeln(
        '// **************************************************************************',
      )
      ..writeln('// Fixture Generator - $className Fixture')
      ..writeln(
        '// **************************************************************************',
      )
      ..writeln()
      ..writeln('// GENERATED FIXTURE FILE (YAML Config-Aware)')
      ..writeln(
        '// Create this file at: test/fixtures/${className.snakeCase}.json',
      )
      ..writeln('// Content generated based on YAML configuration:')
      ..writeln('/*');
  }

  void _generateFixtureFile({
    required StringBuffer buffer,
    required String className,
    required ModelVisitor visitor,
    required GeneratorConfig config,
  }) {
    final isMultiFileEnabled = config.multiFileOutput.enabled;
    // Generate fixture comments
    _generateFixtureComments(
      className: className,
      buffer: buffer,
      config: config,
    );

    buffer.writeln('{');

    final fields = visitor.fields.entries.toList();
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final fieldName = field.key;
      final fieldType = field.value;
      final isLast = i == fields.length - 1;

      if (fieldType.isCustomType && !fieldType.toLowerCase().contains('list')) {
        // check if it's a multiFile, if it isn't write a comment and
        // continue otherwise, just continue
        if (!isMultiFileEnabled) {
          buffer.writeln(
            '  // Custom type field: $fieldName ($fieldType) - '
            'This will be injected in the test directly during the fixture '
            'setup',
          );
        }
        continue;
      }

      // Get configured field type from YAML, fallback to default
      final configuredType = _getConfiguredFieldType(
        config,
        className,
        fieldName,
        fieldType,
      );
      final jsonValue = _getJsonValueForConfiguredType(
        fieldType,
        fieldName,
        configuredType,
      );

      final optionalComment = isMultiFileEnabled
          ? ''
          : ' // ${configuredType.isNotEmpty ? 'Configured as: $configuredType' : 'Default type'}';

      buffer.writeln(
        '  "$fieldName": $jsonValue${isLast ? '' : ','}$optionalComment',
      );
    }

    buffer.writeln('}');

    if (!isMultiFileEnabled) {
      buffer
        ..writeln('*/')
        ..writeln();
    }

    // Generate configuration template for unconfigured fields
    _generateConfigurationTemplate(buffer, className, visitor, config);
  }

  String _getJsonValueForType(String fieldType, String fieldName) {
    final type = fieldType.toLowerCase();

    // I've intentionally put the collection types first to avoid
    // misclassification (e.g., 'list of strings' should match 'list' first)
    if (type.startsWith('list')) {
      return '[]';
    } else if (type.contains('map')) {
      return '{}';
    } else if (type.contains('string')) {
      return '"Test $fieldName"';
    } else if (type.contains('int')) {
      return '1';
    } else if (type.contains('double')) {
      return '1.0';
    } else if (type.contains('bool')) {
      return 'true';
    } else if (type.contains('datetime')) {
      return '"2024-01-01T00:00:00.000Z"';
    } else if (type.isCustomType) {
      // For custom types, I'll inject it in the actual test by calling
      // CustomType.empty().toMap() and adding that to the fixture, since I
      // can't possibly get access to the custom type here.
      return '';
    } else {
      // For custom objects, create a minimal structure
      return '{"id": "test_id"}';
    }
  }

  String _getConfiguredFieldType(
    GeneratorConfig config,
    String className,
    String fieldName,
    String fieldType,
  ) {
    // Use the actual YAML configuration
    return config.modelTestConfig.getFieldType(className, fieldName, fieldType);
  }

  /// Get JSON value based on configured type from YAML
  /// for fields that can have multiple formats.
  ///
  /// If no special configuration, falls back to default value.
  String _getJsonValueForConfiguredType(
    String fieldType,
    String fieldName,
    String configuredType,
  ) {
    final type = fieldType.toLowerCase();

    // I've intentionally put the collection types first to avoid
    // misclassification (e.g., 'list of strings' should match 'list' first)
    if (type.startsWith('list')) {
      return '[]';
    } else if (type.contains('map')) {
      return '{}';
    } else if (type.contains('datetime')) {
      switch (configuredType) {
        case 'iso_string':
          return '"2024-01-01T00:00:00.000Z"';
        case 'timestamp_ms':
          return '1704067200000'; // 2024-01-01 in milliseconds
        case 'timestamp_s':
          return '1704067200'; // 2024-01-01 in seconds
        default:
          return '"2024-01-01T00:00:00.000Z"'; // Default to ISO string
      }
    } else if (type.contains('double')) {
      switch (configuredType) {
        case 'double':
          return '1.0';
        case 'int':
          return '1';
        case 'string':
          return '"1.0"';
        default:
          return '1.0';
      }
    } else if (type.contains('int')) {
      switch (configuredType) {
        case 'int':
          return '1';
        case 'string':
          return '"1"';
        default:
          return '1';
      }
    } else {
      // Use the original method for other types
      return _getJsonValueForType(fieldType, fieldName);
    }
  }

  void _generateConfigurationTemplate(
    StringBuffer buffer,
    String className,
    ModelVisitor visitor,
    GeneratorConfig config,
  ) {
    if (config.multiFileOutput.enabled) return;

    buffer
      ..writeln('// CONFIGURATION OPTIONS')
      ..writeln('// Add to clean_arch_config.yaml:')
      ..writeln('/*')
      ..writeln('model_test_config:')
      ..writeln('  ${className.snakeCase}:')
      ..writeln('    field_types:');

    // Generate configuration options for fields that can have multiple formats
    for (final field in visitor.fields.entries) {
      final fieldName = field.key;
      final fieldType = field.value;

      if (fieldType.toLowerCase().contains('datetime')) {
        buffer
          ..writeln(
            '      $fieldName: "iso_string"  # Options: iso_string, '
            'timestamp_ms, timestamp_s',
          )
          ..writeln('        # iso_string: "2024-01-01T00:00:00.000Z"')
          ..writeln('        # timestamp_ms: 1704067200000')
          ..writeln('        # timestamp_s: 1704067200');
      } else if (fieldType.toLowerCase().contains('double')) {
        buffer
          ..writeln(
            '      $fieldName: "double"      # Options: double, int, string',
          )
          ..writeln('        # double: 1.0, int: 1, string: "1.0"');
      } else if (fieldType.toLowerCase().contains('int')) {
        buffer
          ..writeln(
            '      $fieldName: "int"         # Options: int, string',
          )
          ..writeln('        # int: 1, string: "1"');
      }
    }

    buffer
      ..writeln()
      ..writeln('  # Global defaults for all models:')
      ..writeln('  defaults:')
      ..writeln(
        '    datetime_format: "iso_string"  # Default DateTime format',
      )
      ..writeln(
        '    number_format: "double"        # Default number format',
      )
      ..writeln('*/')
      ..writeln()
      // Show current configuration being used
      ..writeln('// CURRENT CONFIGURATION DETECTED:')
      ..writeln('// (Based on YAML config or defaults)');
    for (final field in visitor.fields.entries) {
      final fieldName = field.key;
      final fieldType = field.value;
      final configuredType = _getConfiguredFieldType(
        config,
        className,
        fieldName,
        fieldType,
      );

      if (configuredType.isNotEmpty) {
        buffer.writeln(
          '// $fieldName ($fieldType) -> configured as: $configuredType',
        );
      }
    }
  }
}

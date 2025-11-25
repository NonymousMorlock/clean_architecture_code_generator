// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Improved generator for creating test files for model classes.
///
/// An enhanced version of ModelTestGenerator with better test coverage
/// and more comprehensive test scenarios.
class ModelTestGeneratorImproved
    extends GeneratorForAnnotation<ModelTestGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = ModelVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();
    _generateModelTest(buffer, visitor);
    return buffer.toString();
  }

  void _generateModelTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = visitor.className;
    final modelClassName = '${className}Model';
    final entityClassName = className;

    // Configuration is loaded in individual methods as needed

    // Generate imports
    _generateImports(buffer, className);

    // Generate main test function
    buffer.writeln('void main() {');

    // Generate test model using fixture-based approach
    _generateTestModel(
      buffer,
      className,
      modelClassName,
      entityClassName,
      visitor,
    );

    // Generate tests
    _generateEntitySubclassTest(buffer, modelClassName, entityClassName);
    _generateFromMapTest(buffer, modelClassName);
    _generateToMapTest(buffer, modelClassName);
    _generateCopyWithTest(buffer, modelClassName, visitor);
    _generateFromJsonTest(buffer, modelClassName);
    _generateToJsonTest(buffer, modelClassName);

    buffer.writeln('}');

    // Generate fixture file
    _generateFixtureFile(buffer, className, visitor);
  }

  void _generateImports(StringBuffer buffer, String className) {
    final classSnakeCase = className.snakeCase;

    // Load configuration to get app name
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final appName = config.appName;
    final rootName = config.featureScaffolding.rootName;

    buffer
      ..writeln("import 'dart:convert';")
      ..writeln()
      ..writeln("import 'package:flutter_test/flutter_test.dart';")
      ..writeln()
      ..writeln('// Feature imports')
      ..writeln("import 'package:$appName/core/typedefs.dart';")
      ..writeln(
        "import 'package:$appName/$rootName/$classSnakeCase/data/models/${classSnakeCase}_model.dart';",
      )
      ..writeln(
        "import 'package:$appName/$rootName/$classSnakeCase/domain/entities/$classSnakeCase.dart';",
      )
      ..writeln()
      ..writeln('// Test utilities')
      ..writeln("import '../../../fixtures/fixture_reader.dart';")
      ..writeln();
  }

  void _generateTestModel(
    StringBuffer buffer,
    String className,
    String modelClassName,
    String entityClassName,
    ModelVisitor visitor,
  ) {
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
    _generateFixtureTransformations(buffer, visitor);

    buffer
      ..writeln('    // Create test model from fixture data')
      ..writeln('    t$modelClassName = $modelClassName.fromMap(tMap);')
      ..writeln('  });')
      ..writeln();
  }

  void _generateFixtureTransformations(
    StringBuffer buffer,
    ModelVisitor visitor,
  ) {
    buffer.writeln(
      '    // Transform fixture data to match expected types (YAML config-aware)',
    );
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

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
      }
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

  void _generateFixtureFile(
    StringBuffer buffer,
    String className,
    ModelVisitor visitor,
  ) {
    // Load configuration to determine field types
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

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
      ..writeln('/*')
      ..writeln('{');

    final fields = visitor.fields.entries.toList();
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final fieldName = field.key;
      final fieldType = field.value;
      final isLast = i == fields.length - 1;

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

      buffer.writeln(
        '  "$fieldName": $jsonValue${isLast ? '' : ','} // ${configuredType.isNotEmpty ? 'Configured as: $configuredType' : 'Default type'}',
      );
    }

    buffer
      ..writeln('}')
      ..writeln('*/')
      ..writeln();

    // Generate configuration template for unconfigured fields
    _generateConfigurationTemplate(buffer, className, visitor, config);
  }

  String _getJsonValueForType(String fieldType, String fieldName) {
    final type = fieldType.toLowerCase();

    if (type.contains('string')) {
      return '"Test $fieldName"';
    } else if (type.contains('int')) {
      return '1';
    } else if (type.contains('double')) {
      return '1.0';
    } else if (type.contains('bool')) {
      return 'true';
    } else if (type.contains('datetime')) {
      return '"2024-01-01T00:00:00.000Z"';
    } else if (type.startsWith('list')) {
      return '[]';
    } else if (type.contains('map')) {
      return '{}';
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

  String _getJsonValueForConfiguredType(
    String fieldType,
    String fieldName,
    String configuredType,
  ) {
    final type = fieldType.toLowerCase();

    if (type.contains('datetime')) {
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

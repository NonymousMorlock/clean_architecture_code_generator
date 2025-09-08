// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

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

    // Load configuration
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

    // Generate imports
    _generateImports(buffer, className);

    // Generate main test function
    buffer.writeln('void main() {');

    // Generate test model using fixture-based approach
    _generateTestModel(
        buffer, className, modelClassName, entityClassName, visitor);

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

    buffer.writeln('import \'dart:convert\';');
    buffer.writeln();
    buffer.writeln('import \'package:flutter_test/flutter_test.dart\';');
    buffer.writeln();
    buffer.writeln('// Feature imports');
    buffer.writeln('import \'package:your_app/core/typedefs.dart\';');
    buffer.writeln(
        'import \'package:your_app/features/$classSnakeCase/data/models/${classSnakeCase}_model.dart\';');
    buffer.writeln(
        'import \'package:your_app/features/$classSnakeCase/domain/entities/$classSnakeCase.dart\';');
    buffer.writeln();
    buffer.writeln('// Test utilities');
    buffer.writeln('import \'../../../fixtures/fixture_reader.dart\';');
    buffer.writeln();
  }

  void _generateTestModel(StringBuffer buffer, String className,
      String modelClassName, String entityClassName, ModelVisitor visitor) {
    buffer
        .writeln('  // Test model created from fixture to ensure consistency');
    buffer.writeln('  late $modelClassName t${modelClassName};');
    buffer.writeln('  late DataMap tMap;');
    buffer.writeln();
    buffer.writeln('  setUpAll(() {');
    buffer.writeln('    // Load fixture and create model from it');
    buffer.writeln(
        '    final fixtureString = fixture(\'${className.snakeCase}.json\');');
    buffer.writeln('    tMap = jsonDecode(fixtureString) as DataMap;');
    buffer.writeln();

    // Handle special field transformations for fixtures
    _generateFixtureTransformations(buffer, visitor);

    buffer.writeln('    // Create test model from fixture data');
    buffer.writeln('    t${modelClassName} = $modelClassName.fromMap(tMap);');
    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateFixtureTransformations(
      StringBuffer buffer, ModelVisitor visitor) {
    buffer.writeln(
        '    // Transform fixture data to match expected types (YAML config-aware)');
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

    for (final field in visitor.fields.entries) {
      final fieldName = field.key;
      final fieldType = field.value;
      final configuredType =
          _getConfiguredFieldType(config, 'className', fieldName, fieldType);

      if (fieldType.toLowerCase().contains('datetime')) {
        buffer.writeln(
            '    // Handle DateTime field: $fieldName (configured as: $configuredType)');

        switch (configuredType) {
          case 'timestamp_ms':
          case 'timestamp_s':
            buffer.writeln('    if (tMap[\'$fieldName\'] is String) {');
            buffer.writeln(
                '      // Convert ISO string to timestamp for API consistency');
            buffer.writeln(
                '      final dateTime = DateTime.parse(tMap[\'$fieldName\'] as String);');
            if (configuredType == 'timestamp_ms') {
              buffer.writeln(
                  '      tMap[\'$fieldName\'] = dateTime.millisecondsSinceEpoch;');
            } else {
              buffer.writeln(
                  '      tMap[\'$fieldName\'] = dateTime.millisecondsSinceEpoch ~/ 1000;');
            }
            buffer.writeln('    }');
            break;
          case 'iso_string':
          default:
            buffer.writeln('    if (tMap[\'$fieldName\'] is int) {');
            buffer.writeln(
                '      // Convert timestamp to ISO string for API consistency');
            buffer.writeln(
                '      final timestamp = tMap[\'$fieldName\'] as int;');
            buffer.writeln('      final dateTime = timestamp > 1000000000000');
            buffer.writeln(
                '          ? DateTime.fromMillisecondsSinceEpoch(timestamp)');
            buffer.writeln(
                '          : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);');
            buffer.writeln(
                '      tMap[\'$fieldName\'] = dateTime.toIso8601String();');
            buffer.writeln('    }');
            break;
        }
      } else if (fieldType.toLowerCase().contains('double') &&
          configuredType.isNotEmpty) {
        buffer.writeln(
            '    // Handle double field: $fieldName (configured as: $configuredType)');
        switch (configuredType) {
          case 'int':
            buffer.writeln('    if (tMap[\'$fieldName\'] is double) {');
            buffer.writeln(
                '      tMap[\'$fieldName\'] = (tMap[\'$fieldName\'] as double).toInt();');
            buffer.writeln('    }');
            break;
          case 'string':
            buffer.writeln('    if (tMap[\'$fieldName\'] is num) {');
            buffer.writeln(
                '      tMap[\'$fieldName\'] = tMap[\'$fieldName\'].toString();');
            buffer.writeln('    }');
            break;
          case 'double':
          default:
            buffer.writeln('    if (tMap[\'$fieldName\'] is int) {');
            buffer.writeln(
                '      tMap[\'$fieldName\'] = (tMap[\'$fieldName\'] as int).toDouble();');
            buffer.writeln('    }');
            break;
        }
      } else if (fieldType.toLowerCase().contains('int') &&
          configuredType == 'string') {
        buffer.writeln(
            '    // Handle int field: $fieldName (configured as: string)');
        buffer.writeln('    if (tMap[\'$fieldName\'] is int) {');
        buffer.writeln(
            '      tMap[\'$fieldName\'] = tMap[\'$fieldName\'].toString();');
        buffer.writeln('    }');
      }
    }
    buffer.writeln();
  }

  void _generateEntitySubclassTest(
      StringBuffer buffer, String modelClassName, String entityClassName) {
    buffer.writeln(
        '  test(\'should be a subclass of $entityClassName entity\', () {');
    buffer.writeln('    expect(t$modelClassName, isA<$entityClassName>());');
    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateFromMapTest(StringBuffer buffer, String modelClassName) {
    buffer.writeln('  group(\'fromMap\', () {');
    buffer.writeln('    test(');
    buffer.writeln(
        '      \'should return a valid model when the map is valid\',');
    buffer.writeln('      () {');
    buffer.writeln('        final result = $modelClassName.fromMap(tMap);');
    buffer.writeln();
    buffer.writeln('        expect(result, isA<$modelClassName>());');
    buffer.writeln('        expect(result, equals(t$modelClassName));');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln('    test(');
    buffer.writeln(
        '      \'should handle null values gracefully for optional fields\',');
    buffer.writeln('      () {');
    buffer.writeln(
        '        final mapWithNulls = Map<String, dynamic>.from(tMap);');
    buffer.writeln('        // Set optional fields to null');
    buffer.writeln('        // mapWithNulls[\'optionalField\'] = null;');
    buffer.writeln();
    buffer.writeln(
        '        final result = $modelClassName.fromMap(mapWithNulls);');
    buffer.writeln();
    buffer.writeln('        expect(result, isA<$modelClassName>());');
    buffer.writeln('        // Add specific assertions for null handling');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateToMapTest(StringBuffer buffer, String modelClassName) {
    buffer.writeln('  group(\'toMap\', () {');
    buffer.writeln('    test(');
    buffer.writeln(
        '      \'should return a JSON map containing the proper data\',');
    buffer.writeln('      () {');
    buffer.writeln('        final result = t$modelClassName.toMap();');
    buffer.writeln();
    buffer.writeln('        expect(result, isA<DataMap>());');
    buffer.writeln(
        '        // Compare key fields to ensure proper serialization');
    buffer.writeln('        expect(result[\'id\'], t$modelClassName.id);');
    buffer.writeln('        // Add more field comparisons as needed');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateCopyWithTest(
      StringBuffer buffer, String modelClassName, ModelVisitor visitor) {
    buffer.writeln('  group(\'copyWith\', () {');

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

    buffer.writeln('    test(');
    buffer.writeln(
        '      \'should return a copy of the model with updated fields\',');
    buffer.writeln('      () {');

    String testValue;
    if (testFieldType!.toLowerCase().contains('string')) {
      testValue = '\'Updated ${testField!}\'';
    } else if (testFieldType.toLowerCase().contains('int')) {
      testValue = '999';
    } else if (testFieldType.toLowerCase().contains('double')) {
      testValue = '99.9';
    } else if (testFieldType.toLowerCase().contains('bool')) {
      testValue = '!t$modelClassName.$testField';
    } else {
      testValue = 'null'; // For complex types
    }

    buffer.writeln(
        '        final result = t$modelClassName.copyWith($testField: $testValue);');
    buffer.writeln();
    buffer.writeln('        expect(result, isA<$modelClassName>());');
    buffer.writeln('        expect(result.$testField, $testValue);');
    buffer.writeln('        // Ensure other fields remain unchanged');

    // Test that other fields remain the same
    for (final field in visitor.fields.entries) {
      final fieldName = field.key.camelCase;
      if (fieldName != testField) {
        buffer.writeln(
            '        expect(result.$fieldName, t$modelClassName.$fieldName);');
        break; // Just test one other field to keep it concise
      }
    }

    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln();

    buffer.writeln('    test(');
    buffer.writeln(
        '      \'should return the same instance when no parameters are provided\',');
    buffer.writeln('      () {');
    buffer.writeln('        final result = t$modelClassName.copyWith();');
    buffer.writeln();
    buffer.writeln('        expect(result, equals(t$modelClassName));');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateFromJsonTest(StringBuffer buffer, String modelClassName) {
    buffer.writeln('  group(\'fromJson\', () {');
    buffer.writeln('    test(');
    buffer.writeln(
        '      \'should return a valid model when the JSON string is valid\',');
    buffer.writeln('      () {');
    buffer.writeln('        final jsonString = jsonEncode(tMap);');
    buffer.writeln(
        '        final result = $modelClassName.fromJson(jsonString);');
    buffer.writeln();
    buffer.writeln('        expect(result, isA<$modelClassName>());');
    buffer.writeln('        expect(result, equals(t$modelClassName));');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateToJsonTest(StringBuffer buffer, String modelClassName) {
    buffer.writeln('  group(\'toJson\', () {');
    buffer.writeln('    test(');
    buffer.writeln(
        '      \'should return a JSON string containing the proper data\',');
    buffer.writeln('      () {');
    buffer.writeln('        final result = t$modelClassName.toJson();');
    buffer.writeln('        final expectedJson = jsonEncode(tMap);');
    buffer.writeln();
    buffer.writeln('        expect(result, isA<String>());');
    buffer.writeln(
        '        // Parse both to compare as maps (order-independent)');
    buffer.writeln('        final resultMap = jsonDecode(result) as DataMap;');
    buffer.writeln(
        '        final expectedMap = jsonDecode(expectedJson) as DataMap;');
    buffer.writeln('        expect(resultMap, equals(expectedMap));');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  });');
    buffer.writeln();
  }

  void _generateFixtureFile(
      StringBuffer buffer, String className, ModelVisitor visitor) {
    // Load configuration to determine field types
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

    buffer.writeln();
    buffer.writeln(
        '// **************************************************************************');
    buffer.writeln('// Fixture Generator - ${className} Fixture');
    buffer.writeln(
        '// **************************************************************************');
    buffer.writeln();
    buffer.writeln('// GENERATED FIXTURE FILE (YAML Config-Aware)');
    buffer.writeln(
        '// Create this file at: test/fixtures/${className.snakeCase}.json');
    buffer.writeln('// Content generated based on YAML configuration:');
    buffer.writeln('/*');
    buffer.writeln('{');

    final fields = visitor.fields.entries.toList();
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final fieldName = field.key;
      final fieldType = field.value;
      final isLast = i == fields.length - 1;

      // Get configured field type from YAML, fallback to default
      final configuredType =
          _getConfiguredFieldType(config, className, fieldName, fieldType);
      final jsonValue =
          _getJsonValueForConfiguredType(fieldType, fieldName, configuredType);

      buffer.writeln(
          '  "$fieldName": $jsonValue${isLast ? '' : ','} // ${configuredType.isNotEmpty ? 'Configured as: $configuredType' : 'Default type'}');
    }

    buffer.writeln('}');
    buffer.writeln('*/');
    buffer.writeln();

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

  String _getConfiguredFieldType(GeneratorConfig config, String className,
      String fieldName, String fieldType) {
    // Use the actual YAML configuration
    return config.modelTestConfig.getFieldType(className, fieldName, fieldType);
  }

  String _getJsonValueForConfiguredType(
      String fieldType, String fieldName, String configuredType) {
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

  void _generateConfigurationTemplate(StringBuffer buffer, String className,
      ModelVisitor visitor, GeneratorConfig config) {
    buffer.writeln('// CONFIGURATION OPTIONS');
    buffer.writeln('// Add to clean_arch_config.yaml:');
    buffer.writeln('/*');
    buffer.writeln('model_test_config:');
    buffer.writeln('  ${className.snakeCase}:');
    buffer.writeln('    field_types:');

    // Generate configuration options for fields that can have multiple formats
    for (final field in visitor.fields.entries) {
      final fieldName = field.key;
      final fieldType = field.value;

      if (fieldType.toLowerCase().contains('datetime')) {
        buffer.writeln(
            '      $fieldName: "iso_string"  # Options: iso_string, timestamp_ms, timestamp_s');
        buffer.writeln('        # iso_string: "2024-01-01T00:00:00.000Z"');
        buffer.writeln('        # timestamp_ms: 1704067200000');
        buffer.writeln('        # timestamp_s: 1704067200');
      } else if (fieldType.toLowerCase().contains('double')) {
        buffer.writeln(
            '      $fieldName: "double"      # Options: double, int, string');
        buffer.writeln('        # double: 1.0, int: 1, string: "1.0"');
      } else if (fieldType.toLowerCase().contains('int')) {
        buffer
            .writeln('      $fieldName: "int"         # Options: int, string');
        buffer.writeln('        # int: 1, string: "1"');
      }
    }

    buffer.writeln();
    buffer.writeln('  # Global defaults for all models:');
    buffer.writeln('  defaults:');
    buffer.writeln(
        '    datetime_format: "iso_string"  # Default DateTime format');
    buffer
        .writeln('    number_format: "double"        # Default number format');
    buffer.writeln('*/');
    buffer.writeln();

    // Show current configuration being used
    buffer.writeln('// CURRENT CONFIGURATION DETECTED:');
    buffer.writeln('// (Based on YAML config or defaults)');
    for (final field in visitor.fields.entries) {
      final fieldName = field.key;
      final fieldType = field.value;
      final configuredType =
          _getConfiguredFieldType(config, className, fieldName, fieldType);

      if (configuredType.isNotEmpty) {
        buffer.writeln(
            '// $fieldName ($fieldType) -> configured as: $configuredType');
      }
    }
  }
}

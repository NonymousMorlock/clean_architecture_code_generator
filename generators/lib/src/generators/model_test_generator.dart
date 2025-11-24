// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/src/generators/model_test_generator_improved.dart';
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
    // Use the improved model test generator
    final improvedGenerator = ModelTestGeneratorImproved();
    return improvedGenerator.generateForAnnotatedElement(
      element,
      annotation,
      buildStep,
    );
  }

  /// Generates the main test structure for the model.
  ///
  /// Creates the test file with all test groups for serialization,
  /// deserialization, and copyWith methods.
  void testMain(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    // final length = visitor.fields.length;

    // TODO(Fix): Correct this to allow the import, this fails because we
    //  generate part files and they have the part directive which is
    //  not allowed in imports.
    // buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    // buffer.writeln("import 'dart:convert';");
    // buffer.writeln(
    //     "import '${visitor.fieldProperties.values.first.filePath
    //     .replaceAll(';', '')}';"
    //     );
    buffer
      ..writeln()
      ..writeln('void main() {')
      ..writeln('final t$className = $className.empty();')
      ..writeln()
      ..writeln("group('$className', () {")
      ..writeln(
        "test('should be a subclass of [${visitor.className}] entity', "
        '() async {',
      )
      ..writeln('expect(t$className, isA<${visitor.className}>());')
      ..writeln('});')
      ..writeln();
    fromMapTest(buffer, visitor);
    buffer.writeln();
    fromJsonTest(buffer, visitor);
    buffer.writeln();
    toMapTest(buffer, visitor);
    buffer.writeln();
    toJsonTest(buffer, visitor);
    buffer.writeln();
    copyWithTest(buffer, visitor);
    buffer
      ..writeln('});')
      ..writeln('}');
  }

  /// Generates tests for the fromMap factory constructor.
  void fromMapTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer
      ..writeln("group('fromMap', () {")
      ..writeln(
        "test('should return a valid [$className] when the JSON is not "
        "null', () async {",
      )
      ..writeln(
        'final map = '
        "jsonDecode(fixture('${visitor.className.snakeCase}.json')) "
        'as DataMap;',
      )
      ..writeln('final result = $className.fromMap(map);')
      ..writeln('expect(result, t$className);')
      ..writeln('});')
      ..writeln('});');
  }

  /// Generates tests for the fromJson factory constructor.
  void fromJsonTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer
      ..writeln("group('fromJson', () {")
      ..writeln(
        "test('should return a valid [$className] when the JSON is "
        "not null', () async {",
      )
      ..writeln(
        "final json = fixture('${visitor.className.snakeCase}.json');",
      )
      ..writeln('final result = $className.fromJson(json);')
      ..writeln('expect(result, t$className);')
      ..writeln('});')
      ..writeln('});');
  }

  /// Generates tests for the toMap method.
  void toMapTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer
      ..writeln("group('toMap', () {")
      ..writeln(
        "test('should return a Dart map containing the proper "
        "data', () async {",
      )
      ..writeln(
        'final map = '
        "jsonDecode(fixture('${visitor.className.snakeCase}.json"
        "')) as DataMap;",
      )
      ..writeln('final result = t$className.toMap();')
      ..writeln('expect(result, map);')
      ..writeln('});')
      ..writeln('});');
  }

  /// Generates tests for the toJson method.
  void toJsonTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer
      ..writeln("group('toJson', () {")
      ..writeln(
        "test('should return a JSON string containing the proper data', "
        '() async {',
      )
      ..writeln(
        'final json = '
        "jsonEncode(jsonDecode(fixture('${visitor.className.snakeCase}.json"
        "')));",
      )
      ..writeln('final result = t$className.toJson();')
      ..writeln('expect(result, json);')
      ..writeln('});')
      ..writeln('});');
  }

  /// Generates tests for the copyWith method.
  void copyWithTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer
      ..writeln("group('copyWith', () {")
      ..writeln(
        "test('should return a new [$className] with the same values', "
        '() async {',
      );
    MapEntry<String, dynamic>? pickedField;
    for (final field in visitor.fields.entries) {
      final fieldType = field.value.toLowerCase();
      if (fieldType.contains('string') ||
          fieldType.contains('int') ||
          fieldType.contains('double') ||
          fieldType.contains('bool')) {
        pickedField = field;
        break;
      }
    }
    if (pickedField == null) {
      buffer
        ..writeln('final result = t$className.copyWith();')
        ..writeln('expect(result, $className);');
    } else {
      final fallback = pickedField.value.toString().copyWithFallback;
      final fieldName = pickedField.key.camelCase;
      buffer
        ..writeln(
          'final result = t$className.copyWith($fieldName: $fallback);',
        )
        ..writeln('expect(result.$fieldName, equals($fallback));');
    }
    buffer
      ..writeln('});')
      ..writeln('});');
  }
}

// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

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

    final buffer = StringBuffer();
    testMain(buffer, visitor);
    return buffer.toString();
  }

  void testMain(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    final length = visitor.fields.length;

    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln("import 'dart:convert';");
    buffer.writeln(
        "import '${visitor.fieldProperties.values.first.filePath.replaceAll(';', '')}';");
    buffer.writeln();
    buffer.writeln('void main() {');
    buffer.writeln('final t$className = $className(');
    for (var i = 0; i < length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final fallback =
          visitor.fields.values.elementAt(i).toString().fallbackValue;
      buffer.writeln(
          '$name: ${fallback is String ? '"$fallback"' : '$fallback'},');
    }
    buffer.writeln(');');
    buffer.writeln();
    buffer.writeln("group('$className', () {");
    buffer.writeln(
        "test('should be a subclass of [${visitor.className}] entity', () async {");
    buffer.writeln("expect(t$className, isA<${visitor.className}>());");
    buffer.writeln("});");
    buffer.writeln();
    fromMapTest(buffer, visitor);
    buffer.writeln();
    fromJsonTest(buffer, visitor);
    buffer.writeln();
    toMapTest(buffer, visitor);
    buffer.writeln();
    toJsonTest(buffer, visitor);
    buffer.writeln();
    copyWithTest(buffer, visitor);
    buffer.writeln("});");
    buffer.writeln("}");
  }

  void fromMapTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer.writeln("group('fromMap', () {");
    buffer.writeln(
        "test('should return a valid [$className] when the JSON is not null', () async {");
    buffer.writeln(
        "final map = jsonDecode(fixture('${visitor.className.toLowerCase()}.json')) as DataMap;");
    buffer.writeln("final result = $className.fromMap(map);");
    buffer.writeln("expect(result, t$className);");
    buffer.writeln("});");
    buffer.writeln("});");
  }

  void fromJsonTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer.writeln("group('fromJson', () {");
    buffer.writeln(
        "test('should return a valid [$className] when the JSON is not null', () async {");
    buffer.writeln(
        "final json = fixture('${visitor.className.toLowerCase()}.json');");
    buffer.writeln("final result = $className.fromJson(json);");
    buffer.writeln("expect(result, t$className);");
    buffer.writeln("});");
    buffer.writeln("});");
  }

  void toMapTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer.writeln("group('toMap', () {");
    buffer.writeln(
        "test('should return a Dart map containing the proper data', () async {");
    buffer.writeln(
        "final map = jsonDecode(fixture('${visitor.className.toLowerCase()}.json')) as DataMap;");
    buffer.writeln("final result = t$className.toMap();");
    buffer.writeln("expect(result, map);");
    buffer.writeln("});");
    buffer.writeln("});");
  }

  void toJsonTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer.writeln("group('toJson', () {");
    buffer.writeln(
        "test('should return a JSON string containing the proper data', () async {");
    buffer.writeln(
        "final json = jsonEncode(jsonDecode(fixture('${visitor.className.toLowerCase()}.json')));");
    buffer.writeln("final result = t$className.toJson();");
    buffer.writeln("expect(result, json);");
    buffer.writeln("});");
    buffer.writeln("});");
  }

  void copyWithTest(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer.writeln("group('copyWith', () {");
    buffer.writeln(
        "test('should return a new [$className] with the same values', () async {");
    MapEntry<String, dynamic>? pickedField;
    for (final field in visitor.fields.entries) {
      if (field.value is String ||
          field.value is int ||
          field.value is double ||
          field.value is bool) {
        pickedField = field;
        break;
      }
    }
    if (pickedField == null) {
      buffer.writeln("final result = t$className.copyWith();");
      buffer.writeln("expect(result, $className);");
    } else {
      final fallback = pickedField.value.toString().copyWithFallback;
      final fieldName = pickedField.key.camelCase;
      buffer.writeln(
          'final result = t$className.copyWith($fieldName: $fallback);');
      buffer.writeln('expect(result.$fieldName, equals($fallback));');
    }
    buffer.writeln("});");
    buffer.writeln("});");
  }
}

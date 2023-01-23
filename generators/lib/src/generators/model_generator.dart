// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

class ModelGenerator extends GeneratorForAnnotation<ModelGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = ModelVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();
    constructor(buffer, visitor);
    return buffer.toString();
  }

  void constructor(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    final length = visitor.fields.length;

    buffer.writeln("// import typedefs");
    buffer.writeln("// import entity");
    buffer.writeln();
    buffer.writeln('class $className extends ${visitor.className} {');
    buffer.writeln('const $className({');
    for (var i = 0; i < length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('${field.isRequired ? 'required ' : ''}super.$name,');
    }
    buffer.writeln('});');
    buffer.writeln();
    fromJson(buffer, visitor);
    buffer.writeln();
    fromMap(buffer, visitor);
    buffer.writeln();
    copyWith(buffer, visitor);
    buffer.writeln();
    toMap(buffer, visitor);
    buffer.writeln();
    toJson(buffer);
    buffer.writeln('}');
  }

  void fromMap(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer.writeln('$className.fromMap(DataMap map)');
    buffer.writeln(': this(');
    for (var i = 0; i < visitor.fields.length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i);
      final field = visitor.fieldProperties[name.camelCase]!;
      if (type.toLowerCase().startsWith('list')) {
        var value = "$type.from(map['$name'] as List<dynamic>)";
        if (!field.isRequired) {
          value =
              "map['$name'] != null ? $type.from(map['$name'] as List<dynamic>) : null";
        }
        buffer.writeln("${name.camelCase}: $value,");
      } else if (type.toLowerCase().startsWith('int')) {
        var value = "(map['$name'] as num).toInt()";
        if (!field.isRequired) {
          value = "(map['$name'] as num?)?.toInt()";
        }
        buffer.writeln("${name.camelCase}: $value,");
      } else if (type.toLowerCase().startsWith('double')) {
        var value = "(map['$name'] as num).toDouble()";
        if (!field.isRequired) {
          value = "(map['$name'] as num?)?.toDouble()";
        }
        buffer.writeln("${name.camelCase}: $value,");
      } else if (type.toLowerCase().startsWith('datetime')) {
        var value = "DateTime.parse(map['$name'] as String)";
        if (!field.isRequired) {
          value =
              "map['$name'] == null ? null : DateTime.parse(map['$name'] as String)";
        }
        buffer.writeln("${name.camelCase}: $value,");
      } else {
        buffer.writeln(
            "${name.camelCase}: map['$name'] as $type${field.isRequired ? '' : '?'},");
      }
    }
    buffer.writeln(');');
  }

  void fromJson(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer.writeln('factory $className.fromJson(String source) =>');
    buffer.writeln('$className.fromMap(jsonDecode(source) as DataMap);');
  }

  void toMap(StringBuffer buffer, ModelVisitor visitor) {
    buffer.writeln('DataMap toMap() {');
    buffer.writeln('return <String, dynamic>{');
    for (var i = 0; i < visitor.fields.length; i++) {
      final name = visitor.fields.keys.elementAt(i);
      final type = visitor.fields.values.elementAt(i);
      final field = visitor.fieldProperties[name.camelCase]!;
      if (type.toLowerCase().startsWith('datetime')) {
        buffer.writeln(
            "'$name': ${name.camelCase}${field.isRequired ? '' : '?'}.toIso8601String(),");
      } else {
        buffer.writeln("'$name': ${name.camelCase},");
      }
    }
    buffer.writeln('};');
    buffer.writeln('}');
  }

  void toJson(StringBuffer buffer) {
    buffer.writeln('String toJson() => jsonEncode(toMap());');
  }

  void copyWith(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';

    buffer.writeln('$className copyWith({');
    for (var i = 0; i < visitor.fields.length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      buffer.writeln('$type? $name,');
    }
    buffer.writeln('}) {');
    buffer.writeln('return $className(');
    for (var i = 0; i < visitor.fields.length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      buffer.writeln('$name: $name ?? this.$name,');
    }
    buffer.writeln(');');
    buffer.writeln('}');
  }
}

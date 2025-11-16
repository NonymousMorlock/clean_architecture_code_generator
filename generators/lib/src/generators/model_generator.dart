// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

class ModelGenerator extends GeneratorForAnnotation<ModelGenAnnotation> {
  // DIDN'T SOLVE MY ISSUE, HAD TO CHANGE BUILD.YAML CONFIG
  // static const _checker = TypeChecker.fromRuntime(ModelGenAnnotation);
  // unfortunately, after dart 3 update, the generateForAnnotatedElement
  // override was no longer enough to generate the model class, so we had to
  // override generate as well.
  // @override
  // Future<String> generate(LibraryReader library, BuildStep buildStep) async {
  //   final buffer = StringBuffer();
  //   for (var element in library.allElements) {
  //     if (element is ClassElement && _checker.hasAnnotationOfExact(element)) {
  //       final visitor = ModelVisitor();
  //       element.visitChildren(visitor);
  //       constructor(buffer, visitor);
  //     }
  //   }
  //   return buffer.toString();
  // }

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
    buffer.writeln('$className.empty()');
    buffer.writeln(':');
    buffer.writeln('this(');
    for (var i = 0; i < length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      // final field = visitor.fieldProperties[name]!;
      final defaultValue = type.toString().fallbackValue;
      final emptyConstructor = '$type.empty()';
      buffer.writeln(
          '$name: ${defaultValue is String && defaultValue.toLowerCase() == 'test string' ? '"' : ''}${defaultValue ?? emptyConstructor}${defaultValue is String && defaultValue.toLowerCase() == 'test string' ? '"' : ''}${i == length - 1 ? ',);' : ','}');
    }
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
    buffer.writeln();

    // Add DateTime parsing helper method
    _generateDateTimeParsingHelper(buffer);

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
        // Enhanced DateTime parsing to handle multiple API formats
        if (!field.isRequired) {
          buffer.writeln(
              "${name.camelCase}: map['$name'] == null ? null : _parseDateTime(map['$name']),");
        } else {
          buffer.writeln("${name.camelCase}: _parseDateTime(map['$name']),");
        }
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

  void _generateDateTimeParsingHelper(StringBuffer buffer) {
    buffer.writeln(
        '  // Helper method to parse DateTime from various API formats');
    buffer.writeln('  static DateTime _parseDateTime(dynamic value) {');
    buffer.writeln('    if (value is String) {');
    buffer.writeln('      return DateTime.parse(value);');
    buffer.writeln('    } else if (value is int) {');
    buffer.writeln('      // Handle timestamp (milliseconds or seconds)');
    buffer.writeln('      return value > 1000000000000');
    buffer.writeln('          ? DateTime.fromMillisecondsSinceEpoch(value)');
    buffer.writeln(
        '          : DateTime.fromMillisecondsSinceEpoch(value * 1000);');
    buffer.writeln('    } else if (value is double) {');
    buffer.writeln(
        '      return DateTime.fromMillisecondsSinceEpoch(value.toInt());');
    buffer.writeln('    } else {');
    buffer.writeln(
        '      throw FormatException(\'Invalid DateTime format: \$value\');');
    buffer.writeln('    }');
    buffer.writeln('  }');
  }
}

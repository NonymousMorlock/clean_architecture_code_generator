// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating model classes from entity annotations.
///
/// Processes classes annotated with `@ModelGenAnnotation` and generates
/// corresponding model classes in the data layer with JSON serialization.
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
  //     if (element is ClassElement && _checker
  //     .hasAnnotationOfExact(element)) {
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

  /// Generates the model class constructor and all its methods.
  ///
  /// Creates the main constructor, empty constructor, and all
  /// serialization/deserialization methods.
  void constructor(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    final length = visitor.fields.length;

    buffer
      ..writeln('// import typedefs')
      ..writeln('// import entity')
      ..writeln()
      ..writeln('class $className extends ${visitor.className} {')
      ..writeln('const $className({');
    for (var i = 0; i < length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('${field.isRequired ? 'required ' : ''}super.$name,');
    }
    buffer
      ..writeln('});')
      ..writeln()
      ..writeln('$className.empty()')
      ..writeln(':')
      ..writeln('this(');
    for (var i = 0; i < length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      // final field = visitor.fieldProperties[name]!;
      final defaultValue = type.fallbackValue;
      final emptyConstructor = '$type.empty()';
      final optionalQuote =
          defaultValue is String && defaultValue.toLowerCase() == 'test string'
          ? '"'
          : '';
      buffer.writeln(
        '$name: '
        '$optionalQuote'
        '${defaultValue ?? emptyConstructor}'
        '$optionalQuote${i == length - 1 ? ',);' : ','}',
      );
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

  /// Generates the fromMap factory constructor.
  ///
  /// Creates a factory that deserializes a model from a Map,
  /// handling various data types including DateTime and numeric conversions.
  void fromMap(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer
      ..writeln('$className.fromMap(DataMap map)')
      ..writeln(': this(');
    for (var i = 0; i < visitor.fields.length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i);
      final field = visitor.fieldProperties[name.camelCase]!;
      if (type.toLowerCase().startsWith('list')) {
        var value = "$type.from(map['$name'] as List<dynamic>)";
        if (!field.isRequired) {
          value =
              "map['$name'] != null ? $type.from(map['$name'] "
              'as List<dynamic>) : null';
        }
        buffer.writeln('${name.camelCase}: $value,');
      } else if (type.toLowerCase().startsWith('int')) {
        var value = "(map['$name'] as num).toInt()";
        if (!field.isRequired) {
          value = "(map['$name'] as num?)?.toInt()";
        }
        buffer.writeln('${name.camelCase}: $value,');
      } else if (type.toLowerCase().startsWith('double')) {
        var value = "(map['$name'] as num).toDouble()";
        if (!field.isRequired) {
          value = "(map['$name'] as num?)?.toDouble()";
        }
        buffer.writeln('${name.camelCase}: $value,');
      } else if (type.toLowerCase().startsWith('datetime')) {
        // Enhanced DateTime parsing to handle multiple API formats
        if (!field.isRequired) {
          buffer.writeln(
            "${name.camelCase}: map['$name'] == null ? null :"
            " _parseDateTime(map['$name']),",
          );
        } else {
          buffer.writeln("${name.camelCase}: _parseDateTime(map['$name']),");
        }
      } else {
        buffer.writeln(
          "${name.camelCase}: map['$name'] "
          "as $type${field.isRequired ? '' : '?'},",
        );
      }
    }
    buffer.writeln(');');
  }

  /// Generates the fromJson factory constructor.
  ///
  /// Creates a factory that deserializes a model from a JSON string.
  void fromJson(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';
    buffer
      ..writeln('factory $className.fromJson(String source) =>')
      ..writeln('$className.fromMap(jsonDecode(source) as DataMap);');
  }

  /// Generates the toMap method.
  ///
  /// Creates a method that serializes the model to a Map,
  /// properly handling DateTime conversion to ISO 8601 strings.
  void toMap(StringBuffer buffer, ModelVisitor visitor) {
    buffer
      ..writeln('DataMap toMap() {')
      ..writeln('return <String, dynamic>{');
    for (var i = 0; i < visitor.fields.length; i++) {
      final name = visitor.fields.keys.elementAt(i);
      final type = visitor.fields.values.elementAt(i);
      final field = visitor.fieldProperties[name.camelCase]!;
      if (type.toLowerCase().startsWith('datetime')) {
        buffer.writeln(
          "'$name': "
          "${name.camelCase}${field.isRequired ? '' : '?'}.toIso8601String(),",
        );
      } else {
        buffer.writeln("'$name': ${name.camelCase},");
      }
    }
    buffer
      ..writeln('};')
      ..writeln('}');
  }

  /// Generates the toJson method.
  ///
  /// Creates a method that serializes the model to a JSON string.
  void toJson(StringBuffer buffer) {
    buffer.writeln('String toJson() => jsonEncode(toMap());');
  }

  /// Generates the copyWith method.
  ///
  /// Creates a method that returns a new instance with updated values,
  /// following the immutable pattern.
  void copyWith(StringBuffer buffer, ModelVisitor visitor) {
    final className = '${visitor.className}Model';

    buffer.writeln('$className copyWith({');
    for (var i = 0; i < visitor.fields.length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      buffer.writeln('$type? $name,');
    }
    buffer
      ..writeln('}) {')
      ..writeln('return $className(');
    for (var i = 0; i < visitor.fields.length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      buffer.writeln('$name: $name ?? this.$name,');
    }
    buffer
      ..writeln(');')
      ..writeln('}');
  }

  void _generateDateTimeParsingHelper(StringBuffer buffer) {
    buffer
      ..writeln(
        '  // Helper method to parse DateTime from various API formats',
      )
      ..writeln('  static DateTime _parseDateTime(dynamic value) {')
      ..writeln('    if (value is String) {')
      ..writeln('      return DateTime.parse(value);')
      ..writeln('    } else if (value is int) {')
      ..writeln('      // Handle timestamp (milliseconds or seconds)')
      ..writeln('      return value > 1000000000000')
      ..writeln('          ? DateTime.fromMillisecondsSinceEpoch(value)')
      ..writeln(
        '          : DateTime.fromMillisecondsSinceEpoch(value * 1000);',
      )
      ..writeln('    } else if (value is double) {')
      ..writeln(
        '      return DateTime.fromMillisecondsSinceEpoch(value.toInt());',
      )
      ..writeln('    } else {')
      ..writeln(
        r"      throw FormatException('Invalid DateTime format: $value');",
      )
      ..writeln('    }')
      ..writeln('  }');
  }
}

// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating entity classes from model annotations.
///
/// Processes classes annotated with `@EntityGenAnnotation` and generates
/// corresponding entity classes in the domain layer.
class EntityGenerator extends GeneratorForAnnotation<EntityGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = ModelVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();
    final className = visitor.className;
    final length = visitor.fields.length;
    buffer
      ..writeln('class $className extends Equatable {')
      ..writeln('const $className({');
    for (var i = 0; i < length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('${field.isRequired ? 'required ' : ''}this.$name,');
    }
    buffer
      ..writeln('});')
      ..writeln()
      ..writeln('$className.empty()')
      ..writeln(':');
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
        '$name = $optionalQuote'
        '${defaultValue ?? emptyConstructor}'
        '$optionalQuote${i == length - 1 ? ';' : ','}',
      );
    }
    buffer.writeln();
    for (var i = 0; i < length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('final $type${field.isRequired ? '' : '?'} $name;');
    }
    buffer
      ..writeln()
      ..writeln('@override')
      ..writeln('List<dynamic> get props => [');
    for (var i = 0; i < length; i++) {
      final type = visitor.fields.values.elementAt(i);
      if (type.toLowerCase().startsWith('list')) continue;
      final name = visitor.fields.keys.elementAt(i).camelCase;

      buffer.writeln('$name,');
    }
    buffer
      ..writeln('];')
      ..writeln('}');
    return buffer.toString();
  }
}

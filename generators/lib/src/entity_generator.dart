// ignore_for_file: depend_on_referenced_packages
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/src/model_visitor.dart';
import 'package:generators/src/string_extensions.dart';
import 'package:source_gen/source_gen.dart';

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
    buffer.writeln('class $className extends Equatable {');
    buffer.writeln('const $className({');
    for (var i = 0; i < length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('${field.isRequired ? 'required ' : ''}this.$name,');
    }
    buffer.writeln('});');
    buffer.writeln();
    for (var i = 0; i < length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('final $type${field.isRequired ? '' : '?'} $name;');
    }
    buffer.writeln();
    buffer.writeln('@override');
    buffer.writeln('List<dynamic> get props => [');
    for (var i = 0; i < length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;

      buffer.writeln('$name,');
    }
    buffer.writeln('];');
    buffer.writeln('}');
    return buffer.toString();
  }
}

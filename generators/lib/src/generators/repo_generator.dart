// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/functions.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

class RepoGenerator extends GeneratorForAnnotation<RepoGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);
    final buffer = StringBuffer();
    repo(buffer, visitor);
    return buffer.toString();
  }

  void repo(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    buffer.writeln('abstract class $className {');
    if(visitor.methods.length == 1) {
      buffer.writeln('const $className();');
    }
    for(final method in visitor.methods) {
      final returnType = method.returnType.rightType;
      final isStream = method.returnType.startsWith('Stream');
      final param = method.params == null ? '' : method.params!.map((e) =>
      paramToString(method, e)).join(', ');
      final asynchronyType = isStream ? 'Stream' : 'Future';
      buffer.writeln('Result$asynchronyType<$returnType> ${method.name}($param);');
    }
    buffer.writeln('}');
  }
}

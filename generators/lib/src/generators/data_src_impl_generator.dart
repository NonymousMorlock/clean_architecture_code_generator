// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/functions.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

class RemoteDataSrcGenerator
    extends GeneratorForAnnotation<RemoteDataSrcGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();

    remoteDataSource(buffer: buffer, visitor: visitor);
    return buffer.toString();
  }

  void remoteDataSource({
    required StringBuffer buffer,
    required RepoVisitor visitor,
  }) {
    final repoName = visitor.className;
    final dataSrcName =
        '${repoName.substring(0, repoName.length - 4)}RemoteDataSrc';
    buffer.writeln('abstract class $dataSrcName {');
    buffer.writeln();

    for (final method in visitor.methods) {
      final className = repoName.replaceAll('Repo', '');
      final returnType = method.returnType.rightType
          .replaceAll(className, '${className}Model');
      if (method.params != null) {
        buffer.writeln(
            "Future<$returnType> ${method.name}(${method.params!.map((param) => paramToString(method, param)).join(', ')});");
      } else {
        buffer.writeln("Future<$returnType> ${method.name}();");
      }
      buffer.writeln();
    }
    buffer.writeln("}");
    buffer.writeln();
    buffer.writeln("class ${dataSrcName}Impl implements $dataSrcName {");
    buffer.writeln("const ${dataSrcName}Impl(this._client);");
    buffer.writeln();
    buffer.writeln("final http.Client _client;");
    buffer.writeln();
    for (final method in visitor.methods) {
      final className = repoName.replaceAll('Repo', '');
      final returnType = method.returnType.rightType
          .replaceAll(className, '${className}Model');
      if (method.params != null) {
        buffer.writeln("@override");
        buffer.writeln(
            "Future<$returnType> ${method.name}(${method.params!.map((param) => paramToString(method, param)).join(', ')}) async {");
        buffer.writeln("\t// TODO(${method.name}): implement ${method.name}");
        buffer.writeln("throw UnimplementedError();");
        buffer.writeln("}");
        buffer.writeln();
      } else {
        buffer.writeln("@override");
        buffer.writeln("Future<$returnType> ${method.name}() async {");
        buffer.writeln("\t// TODO(${method.name}): implement ${method.name}");
        buffer.writeln("throw UnimplementedError();");
        buffer.writeln("}");
        buffer.writeln();
      }
    }
    buffer.writeln("}");
  }
}

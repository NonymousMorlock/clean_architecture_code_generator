// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/functions.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

class RepoImplGenerator extends GeneratorForAnnotation<RepoImplGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();

    repository(buffer: buffer, visitor: visitor);
    return buffer.toString();
  }

  void repository({
    required StringBuffer buffer,
    required RepoVisitor visitor,
  }) {
    final repoName = visitor.className;
    final className = '${repoName}Impl';
    buffer.writeln('class $className implements $repoName {');
    buffer.writeln('const $className(this._remoteDataSource);');
    buffer.writeln();
    buffer.writeln(
        'final ${repoName.substring(0, repoName.length - 4)}RemoteDataSrc _remoteDataSource;');
    buffer.writeln();
    for (final method in visitor.methods) {
      final returnType = method.returnType.rightType;
      final result = returnType.trim() != 'void' ? 'final result = ' : '';
      final returnResult = returnType.trim() != 'void' ? 'result' : 'null';
      buffer.writeln("@override");
      if (method.params != null) {
        buffer.writeln(
            "FunctionalFuture<$returnType> ${method.name}(${method.params!.map((param) => paramToString(method, param)).join(', ')}) "
            "async {");
        buffer.writeln("try {");
        buffer.writeln(
            "${result}await _remoteDataSource.${method.name}(${method.params!.map((param) => _paramToPass(param)).join(', ')});");
        buffer.writeln(
            "return ${returnResult == 'null' ? 'const ' : ''}Right($returnResult);");
        buffer.writeln("} on ServerException catch (e) {");
        buffer.writeln(
            "return Left(ServerFailure(message: e.message, statusCode: e.statusCode));");
        buffer.writeln("}");
        buffer.writeln("}");
      } else {
        buffer
            .writeln("FunctionalFuture<$returnType> ${method.name}() async {");
        buffer.writeln("try {");
        buffer.writeln("${result}await _remoteDataSource.${method.name}();");
        buffer.writeln("return ${returnResult == 'null' ? 'const ' : ''}Right"
            "($returnResult)"
            ";");
        buffer.writeln("} on ServerException catch (e) {");
        buffer.writeln(
            "return Left(ServerFailure(message: e.message, statusCode: e.statusCode));");
        buffer.writeln("}");
        buffer.writeln("}");
      }
    }
    buffer.writeln("}");
  }

  String _paramToPass(Param param) {
    if (param.isNamed) {
      return '${param.name}: ${param.name}';
    } else {
      return param.name;
    }
  }
}

// FunctionalFuture<${method.returnType.rightType}>

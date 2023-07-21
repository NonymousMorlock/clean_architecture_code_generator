// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

class UsecaseGenerator extends GeneratorForAnnotation<UsecaseGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();

    for (final method in visitor.methods) {
      usecase(buffer: buffer, visitor: visitor, method: method);
    }

    return buffer.toString();
  }

  // if function params is greter than 1, then create params class else just use it

  void usecase({
    required StringBuffer buffer,
    required RepoVisitor visitor,
    required IFunction method,
  }) {
    final repoName = visitor.className;
    final className = method.name.upperCamelCase;
    final needsCustomParams =
        method.params != null && method.params!.length > 1;
    final param = method.params != null
        ? method.params!.length > 1
            ? '${className}Params'
            : method.params![0].type
        : null;
    final returnType = method.returnType.rightType;
    final usecaseType = method.params != null
        ? 'UsecaseWithParams<$returnType, $param>'
        : 'UsecaseWithoutParams<$returnType>';
    buffer.writeln('class $className extends $usecaseType {');
    buffer.writeln('const $className(this._repo);');
    buffer.writeln();
    buffer.writeln('final $repoName _repo;');
    buffer.writeln();
    buffer.writeln('@override');
    buffer.writeln(
        'ResultFuture<$returnType> call(${param == null ? '' : '$param params'}) =>');
    callBody(buffer, needsCustomParams, method, param);
    buffer.writeln('}');
    if (needsCustomParams) {
      buffer.writeln();
      customParam(paramName: param!, params: method.params!, buffer: buffer);
    }
  }

  void callBody(StringBuffer buffer, bool needsCustomParams, IFunction
  method, dynamic param) {
    if(!needsCustomParams) {
      buffer.writeln('_repo.${method.name}(${param == null ? '' : 'params'});');
    } else {
      buffer.writeln('_repo.${method.name}(');
      for(var param in method.params!) {
        buffer.writeln('${param.name}: params.${param.name},');
      }
      buffer.writeln(');');
    }

  }

  void customParam({
    required String paramName,
    required List<Param> params,
    required StringBuffer buffer,
  }) {
    buffer.writeln('class $paramName extends Equatable {');
    buffer.writeln('const $paramName({');
    for (final param in params) {
      buffer.writeln('required this.${param.name},');
    }
    buffer.writeln('});');
    buffer.writeln();
    for (final param in params) {
      buffer.writeln('final ${param.type} ${param.name};');
    }
    buffer.writeln();
    buffer.writeln('@override');
    buffer.writeln('List<dynamic> get props => [');
    for (final param in params) {
      buffer.writeln('${param.name},');
    }
    buffer.writeln('];');
    buffer.writeln('}');
  }
}

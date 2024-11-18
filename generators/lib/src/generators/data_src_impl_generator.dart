// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/functions.dart';
import 'package:generators/core/services/map_extensions.dart';
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
      var returnType = method.returnType.modelizeType;
      final isStream = method.returnType.startsWith('Stream');
      final asynchronyType = isStream ? 'Stream' : 'Future';
      if (method.params != null) {
        final params = method.params!
            .map((param) => paramToString(method, param))
            .join(', ');
        buffer.writeln("$asynchronyType<$returnType> ${method.name}($params);");
      } else {
        buffer.writeln("$asynchronyType<$returnType> ${method.name}();");
      }
      buffer.writeln();
    }
    buffer.writeln("}");
    buffer.writeln();
    buffer.writeln("class ${dataSrcName}Impl implements $dataSrcName {");
    final possibleDependencies = {
      'FirebaseDatabase': 'database',
      'FirebaseFirestore': 'firestore',
      'FirebaseStorage': 'storage',
      'FirebaseAuth': 'auth',
      'http.Client': 'client',
      'Dio': 'dio'
    };
    final dependencies = {};
    for (final dependency in possibleDependencies.entries) {
      stdout
        ..writeln()
        ..writeln('REMOTE DATA SOURCE DEPENDENCIES FOR {$dataSrcName}');
      final result = getTerminalInfo("does it use ${dependency.key}");
      if (result) dependencies.addEntry(dependency);
    }

    if (dependencies.length == 1) {
      final dependency = dependencies.entries.last;
      final type = dependency.key;
      final name = '_${dependency.value}';
      buffer.writeln("const ${dataSrcName}Impl(this.$name);");
      buffer.writeln();
      buffer.writeln("final $type $name;");
    } else if (dependencies.length > 1) {
      buffer.writeln('const ${dataSrcName}Impl({');
      for (final dependency in dependencies.entries) {
        final type = dependency.key;
        final name = dependency.value;
        buffer.writeln('$type $name,');
      }
      buffer.write('}) : ');
      for (var i = 0; i < dependencies.entries.length; i++) {
        final dependency = dependencies.entries.elementAt(i);
        final name = dependency.value;
        final privateName = '_$name';
        final punctuation = i < dependencies.entries.length - 1 ? ',' : ';';
        buffer.writeln('$privateName = $name$punctuation');
      }
      buffer.writeln();
      for (final dependency in dependencies.entries) {
        final type = dependency.key;
        final name = '_${dependency.value}';
        buffer.writeln('final $type $name;');
      }
    }

    buffer.writeln();
    for (final method in visitor.methods) {
      final returnType = method.returnType.modelizeType;
      final isStream = method.returnType.startsWith('Stream');
      final asynchronyType = isStream ? 'Stream' : 'Future';
      final modifier = isStream ? '' : 'async';
      if (method.params != null) {
        final params = method.params!
            .map((param) => paramToString(method, param))
            .join(', ');
        buffer.writeln("@override");
        buffer.writeln(
          "$asynchronyType<$returnType> ${method.name}"
          "($params) $modifier {",
        );
        buffer.writeln("\t// TODO(${method.name}): implement ${method.name}");
        buffer.writeln("throw UnimplementedError();");
        buffer.writeln("}");
        buffer.writeln();
      } else {
        buffer.writeln("@override");
        buffer.writeln(
          "$asynchronyType<$returnType> ${method.name}() "
          "$modifier {",
        );
        buffer.writeln("\t// TODO(${method.name}): implement ${method.name}");
        buffer.writeln("throw UnimplementedError();");
        buffer.writeln("}");
        buffer.writeln();
      }
    }
    buffer.writeln("}");
  }

  bool getTerminalInfo(String question) {
    stdout.write('$question (yes): ');
    final result = stdin.readLineSync() ?? 'yes';
    return !(result.isNotEmpty &&
        result.toLowerCase() != 'yes' &&
        result.toLowerCase() != 'y');
  }
}

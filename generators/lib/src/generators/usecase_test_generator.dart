// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

class UsecaseTestGenerator
    extends GeneratorForAnnotation<UsecaseTestGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final buffer = StringBuffer();
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    final className = visitor.className;
    final tag =
        '''// **************************************************************************
// ${className.snakeCase}.mock.dart
// **************************************************************************
''';
    buffer.writeln(tag);
    buffer.writeln('class Mock$className extends Mock implements $className '
        '{}');
    for (var method in visitor.methods) {
      final hasParams = method.params != null;
      buffer.writeln("// import '${className.snakeCase}.mock.dart';");

      buffer.writeln('void main() {');
      buffer.writeln('late Mock$className repo;');
      buffer.writeln('late ${method.name.upperCamelCase} usecase;');
      final testNames = <String>[];
      if (hasParams) {
        for (final param in method.params!) {
          buffer.writeln();
          final testName = 't${param.name.upperCamelCase}';
          testNames.add(testName);
          if (param.type.fallbackValue is List) {
            buffer.writeln('const $testName = <${param.type.stripType}>[];');
          } else {
            buffer.writeln(
                'const $testName = ${/*isCustom ? '${param.type}.empty();' :*/ param.type.fallbackValue is String ? "'${param.type.fallbackValue}';" : '${param.type.fallbackValue};'}');
          }
        }
      }
      buffer.writeln();
      setUp(buffer, className, method);
      buffer.writeln();
      test(buffer, className, method, testNames);
      buffer.writeln('}');
    }
    return buffer.toString();
  }

  void setUp(StringBuffer buffer, String className, IFunction method) {
    final hasParams = method.params != null;
    buffer.writeln('setUp(() {');
    buffer.writeln('repo = Mock$className();');
    buffer.writeln('usecase = ${method.name.upperCamelCase}(repo);');
    if (hasParams) {
      for (final param in method.params!) {
        buffer.writeln('registerFallbackValue(t${param.name.upperCamelCase});');
      }
    }
    buffer.writeln('});');
  }

  void test(StringBuffer buffer, String className, IFunction method,
      List<String> testNames) {
    final returnType = method.returnType.trim();
    final methodName = method.name;
    buffer.writeln('test(');
    buffer.writeln(returnType.rightType == 'void'
        ? "'should call the [$className.${method.name}]',"
        : "'should return [${method.returnType.rightType}] from the repo',");
    buffer.writeln('() async {');
    buffer.writeln('when(() => repo.$methodName(');
    if (method.params != null) {
      for (final param in method.params!) {
        final fallback = param.isNamed
            ? '${param.name}: any(named: "${param.name}"),'
            : 'any(),';
        buffer.writeln(fallback);
      }
    }
    final fallback = method.returnType.fallbackValue == method.returnType
        ? '${method.returnType.rightType}()'
        : method.returnType.fallbackValue;
    buffer.writeln('),');
    buffer.writeln(')');
    buffer.writeln('.thenAnswer(');
    final isCustom = testNames.length > 1;
    buffer.writeln('(_) async => const Right($fallback),');
    buffer.writeln(');');
    buffer.writeln();
    buffer.writeln(
        'final result = await ${isCustom ? 'usecase(' : testNames.isNotEmpty ? 'usecase'
            '(${testNames[0]});' : 'usecase();'}');
    if (isCustom) {
      final className = '${method.name.upperCamelCase}Params';
      buffer.writeln('const $className(');
      for (final name in testNames) {
        buffer.writeln('${name.replaceFirst('t', '').lowerCamelCase}: $name,');
      }
      buffer.writeln('),');
      buffer.writeln(');');
    }
    buffer.writeln(
        'expect(result, equals(const Right<dynamic, ${method.returnType.rightType}>'
        '($fallback)));');
    buffer.writeln('verify(() => repo.$methodName(');
    if (method.params != null) {
      for (final param in method.params!) {
        final fallback = param.isNamed
            ? '${param.name}: any(named: "${param.name}"),'
            : 'any(),';
        buffer.writeln(fallback);
      }
    }
    buffer.writeln('),).called(1);');
    buffer.writeln('verifyNoMoreInteractions(repo);');
    buffer.writeln('},');
    buffer.writeln(');');
  }
}

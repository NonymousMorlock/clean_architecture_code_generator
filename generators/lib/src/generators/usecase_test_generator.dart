// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating test files for use case classes.
///
/// Processes classes annotated with `@UsecaseTestGenAnnotation` and generates
/// comprehensive test files for use case classes.
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
        '''
// **************************************************************************
// ${className.snakeCase}.mock.dart
// **************************************************************************
''';
    buffer
      ..writeln(tag)
      ..writeln(
        'class Mock$className extends Mock implements $className '
        '{}',
      );
    for (final method in visitor.methods) {
      final hasParams = method.params != null;
      buffer
        ..writeln("// import '${className.snakeCase}.mock.dart';")
        ..writeln('void main() {')
        ..writeln('late Mock$className repo;')
        ..writeln('late ${method.name.upperCamelCase} usecase;');
      final testNames = <String>[];
      if (hasParams) {
        for (final param in method.params!) {
          buffer.writeln();
          final testName = 't${param.name.upperCamelCase}';
          testNames.add(testName);
          if (param.type.fallbackValue is List) {
            buffer.writeln('const $testName = <${param.type.stripType}>[];');
          } else {
            final isCustomType =
                param.type.fallbackValue is String &&
                (param.type.fallbackValue as String).isCustomType;
            final testVariable = isCustomType
                ? '${param.type}.empty();'
                : param.type.fallbackValue is String
                ? "'${param.type.fallbackValue}';"
                : '${param.type.fallbackValue};';
            buffer.writeln(
              '${isCustomType ? 'final' : 'const'} $testName = '
              '$testVariable',
            );
          }
        }
      }
      final methodReturnTypeFallback =
          method.returnType.rightType.fallbackValue;
      final methodReturnsCustomType =
          methodReturnTypeFallback is String &&
          methodReturnTypeFallback.isCustomType;
      if (methodReturnsCustomType) {
        buffer
          ..writeln()
          ..writeln('final tResult = $methodReturnTypeFallback;');
      } else if (methodReturnTypeFallback is String &&
          methodReturnTypeFallback == 'null') {
        // pass
        // means it's got void return type
      } else if (methodReturnTypeFallback is String) {
        buffer
          ..writeln()
          ..writeln("final tResult = '$methodReturnTypeFallback';");
      } else if (methodReturnTypeFallback is List) {
        final listMembersType = method.returnType.rightType.stripType;
        final listMembersDefault = listMembersType.fallbackValue;
        var defaultMember = listMembersDefault;
        if (listMembersDefault is String && listMembersDefault.isCustomType) {
          defaultMember = listMembersDefault;
        } else if (listMembersDefault is String) {
          defaultMember = "'$listMembersDefault'";
        }
        buffer.writeln(
          'final tResult = <$listMembersType>[$defaultMember];',
        );
      } else {
        buffer
          ..writeln()
          ..writeln('final tResult = $methodReturnTypeFallback;');
      }
      buffer.writeln();
      setUp(buffer, className, method);
      buffer.writeln();
      test(buffer, className, method, testNames);
      buffer.writeln('}');
    }
    return buffer.toString();
  }

  /// Generates the setUp method for use case tests.
  ///
  /// Initializes mocks and registers fallback values for parameters.
  void setUp(StringBuffer buffer, String className, IFunction method) {
    final hasParams = method.params != null;
    buffer
      ..writeln('setUp(() {')
      ..writeln('repo = Mock$className();')
      ..writeln('usecase = ${method.name.upperCamelCase}(repo);');
    if (hasParams) {
      for (final param in method.params!) {
        buffer.writeln('registerFallbackValue(t${param.name.upperCamelCase});');
      }
    }
    buffer.writeln('});');
  }

  /// Generates a test case for a use case.
  ///
  /// Creates a comprehensive test that verifies the use case calls
  /// the repository correctly and returns the expected result.
  void test(
    StringBuffer buffer,
    String className,
    IFunction method,
    List<String> testNames,
  ) {
    final returnType = method.returnType.trim();
    final methodName = method.name;
    final isStream = returnType.startsWith('Stream');
    final action = isStream ? 'emit' : 'return';
    buffer
      ..writeln('test(')
      ..writeln(
        returnType.rightType == 'void'
            ? "'should call the [$className.${method.name}]',"
            : "'should $action [${method.returnType.rightType}] "
                  "from the repo',",
      )
      ..writeln('() async {')
      ..writeln('when(() => repo.$methodName(');
    if (method.params != null) {
      for (final param in method.params!) {
        final fallback = param.isNamed
            ? '${param.name}: any(named: "${param.name}"),'
            : 'any(),';
        buffer.writeln(fallback);
      }
    }
    // var fallback = method.returnType.fallbackValue == method.returnType
    //     ? '${method.returnType.rightType}()'
    //     : method.returnType.fallbackValue;
    final returnTypeFallback = method.returnType.fallbackValue;
    final fallback =
        returnTypeFallback is String && returnTypeFallback == 'null'
        ? null
        : 'tResult';
    final hasCustomReturnType =
        returnTypeFallback is String && returnTypeFallback.isCustomType;
    // if (fallback is String && fallback.isCustomType) {
    //   fallback = 'tResult';
    //   hasCustomReturnType = true;
    // }
    buffer
      ..writeln('),')
      ..writeln(')')
      ..writeln('.thenAnswer(');
    final moreThanOneParam = testNames.length > 1;
    final modifier = hasCustomReturnType ? '' : 'const';
    var streamPrefix = '';
    var streamSuffix = '';
    if (isStream) {
      streamPrefix = 'Stream.value(';
      streamSuffix = ')';
    }
    buffer
      ..writeln(
        '(_) async '
        '=> $streamPrefix'
        '$modifier Right($fallback)$streamSuffix,',
      )
      ..writeln(');')
      ..writeln();
    final resultText = isStream ? 'stream' : 'result';
    buffer.writeln(
      'final $resultText = ${isStream ? '' : 'await'} ${moreThanOneParam
          ? 'usecase('
          : testNames.isNotEmpty
          ? 'usecase(${testNames.first});'
          : 'usecase();'}',
    );
    if (moreThanOneParam) {
      final className = '${method.name.upperCamelCase}Params';
      buffer.writeln('const $className(');
      for (final name in testNames) {
        buffer.writeln('${name.replaceFirst('t', '').lowerCamelCase}: $name,');
      }
      buffer
        ..writeln('),')
        ..writeln(');');
    }
    buffer
      ..writeln(
        'expect($resultText, ${isStream ? 'emits' : 'equals'}($modifier '
        'Right<dynamic, ${method.returnType.rightType}>($fallback)));',
      )
      ..writeln('verify(() => repo.$methodName(');
    if (method.params != null) {
      for (final param in method.params!) {
        final fallback = param.isNamed
            ? '${param.name}: any(named: "${param.name}"),'
            : 'any(),';
        buffer.writeln(fallback);
      }
    }
    buffer
      ..writeln('),).called(1);')
      ..writeln('verifyNoMoreInteractions(repo);')
      ..writeln('},')
      ..writeln(');');
  }
}

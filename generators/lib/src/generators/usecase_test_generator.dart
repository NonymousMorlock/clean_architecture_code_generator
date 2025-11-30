// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/extensions/repo_visitor_extensions.dart';
import 'package:generators/generators.dart';
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
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final writer = FeatureFileWriter(config, buildStep);

    if (writer.isMultiFileEnabled) {
      return _generateMultiFile(
        visitor: visitor,
        writer: writer,
        buildStep: buildStep,
      );
    }
    final buffer = StringBuffer();

    _generateUsecaseTests(buffer: buffer, visitor: visitor, writer: writer);
    return buffer.toString();
  }

  String _generateMultiFile({
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
    required BuildStep buildStep,
  }) {
    final className = visitor.className;
    final featureName = writer.extractFeatureName(repoName: className);
    final baseName = writer.extractBaseName(className);

    if (featureName == null) {
      final buffer = StringBuffer();
      _generateUsecaseTests(buffer: buffer, visitor: visitor, writer: writer);
      return buffer.toString();
    }

    final mockFilePath = writer.getUsecasesRepoMockPath(featureName);
    final mockBuffer = StringBuffer();
    // write to the .mock file
    _writeMockFile(
      filePath: mockFilePath,
      buffer: mockBuffer,
      writer: writer,
      className: className,
      featureName: featureName,
      baseName: baseName,
    );

    final results = <String>[];

    for (final method in visitor.methods) {
      final usecaseBuffer = StringBuffer()
        ..writeln("import '${className.snakeCase}.mock.dart';");

      final candidates = Utils.discoverMethodEntities(method);
      writer
          .getSmartEntityImports(
            entities: candidates,
            currentFeature: featureName,
          )
          .forEach(usecaseBuffer.writeln);

      _generateUsecaseTestFromMethod(
        buffer: usecaseBuffer,
        className: className,
        method: method,
        writer: writer,
      );

      final usecaseFilePath = writer.getUsecaseTestPath(
        featureName,
        method.name,
      );
      try {
        writer.writeToFile(usecaseFilePath, usecaseBuffer.toString());
        results.add(
          '// Usecase test ${method.name} written to: $usecaseFilePath',
        );
      } on Exception catch (e) {
        stderr.writeln('Warning: Could not write to $usecaseFilePath: $e');
        results.add('// Error writing usecase test ${method.name}: $e\n');
      }
    }
    return '${results.join('\n')}\n';
  }

  void _writeMockFile({
    required String filePath,
    required StringBuffer buffer,
    required FeatureFileWriter writer,
    required String className,
    required String featureName,
    required String baseName,
  }) {
    buffer
      ..writeln("import 'package:mocktail/mocktail.dart';")
      ..writeln(
        writer.getRepositoryImportStatement(
          baseName: baseName,
          featureName: featureName,
        ),
      )
      ..writeln()
      ..writeln('class Mock$className extends Mock implements $className {}');
    try {
      writer.writeToFile(filePath, buffer.toString());
    } on Exception catch (e) {
      stderr.writeln('Warning: Could not write to $filePath: $e');
    }
  }

  void _generateUsecaseTests({
    required StringBuffer buffer,
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
  }) {
    final className = visitor.className;

    final usedEntities = visitor.discoverRequiredEntities();

    writer.getRepoTestImports()
      ..add("import '${className.snakeCase}.mock.dart';")
      ..forEach(buffer.writeln);

    final featureName = writer.extractFeatureName()!;

    writer.getSmartEntityImports(
      entities: usedEntities,
      currentFeature: featureName,
    );

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
      _generateUsecaseTestFromMethod(
        buffer: buffer,
        className: className,
        method: method,
        writer: writer,
      );
    }
  }

  void _generateUsecaseTestFromMethod({
    required StringBuffer buffer,
    required String className,
    required IFunction method,
    required FeatureFileWriter writer,
  }) {
    final hasParams = method.params != null;
    final featureName = writer.extractFeatureName(repoName: className);

    if (featureName != null) {
      buffer
        ..writeln(
          writer.getUsecaseImportStatement(
            featureName: featureName,
            methodName: method.name,
          ),
        )
        ..writeln();
    }

    buffer
      ..writeln('void main() {')
      ..writeln('  late Mock$className repo;')
      ..writeln('  late ${method.name.upperCamelCase} usecase;');

    final testNames = <String>[];

    // 3. PARAMETER GENERATION (Simplified)
    if (hasParams) {
      for (final param in method.params!) {
        buffer.writeln();
        final testName = 't${param.name.upperCamelCase}';
        testNames.add(testName);

        // LOGIC: Trust the extension.
        // fallbackValue returns code string: "User.empty()", "[]", "1", "\"Test\""
        final value = param.type.fallbackValue;

        // LOGIC: isCustomType on the type string decides const/final
        final isCustom = param.type.isCustomType;

        // Exception: Lists are always not const if they contain custom types,
        // but '[]' can be const. For safety in tests, 'final'
        // is usually fine for lists.
        final keyword = (isCustom || param.type.toLowerCase().contains('list'))
            ? 'final'
            : 'const';

        buffer.writeln('  $keyword $testName = $value;');
      }
    }

    // 4. RESULT GENERATION (Simplified)
    final methodReturnType =
        method.returnType.rightType; // Handle Future/Either automatically
    final resultValue = methodReturnType.fallbackValue;

    // Only generate tResult if it's not void
    if (resultValue != 'null') {
      final isResultCustom = methodReturnType.isCustomType;
      final keyword =
          (isResultCustom || methodReturnType.toLowerCase().contains('list'))
          ? 'final'
          : 'const';

      buffer
        ..writeln()
        ..writeln('  $keyword tResult = $resultValue;');
    }

    buffer.writeln();
    _generateSetUp(buffer, className, method);
    buffer.writeln();
    _generateActualTest(buffer, className, method, testNames, resultValue);
    buffer.writeln('}');
  }

  void _generateSetUp(StringBuffer buffer, String className, IFunction method) {
    buffer
      ..writeln('  setUp(() {')
      ..writeln('    repo = Mock$className();')
      ..writeln('    usecase = ${method.name.upperCamelCase}(repo);');

    if (method.params != null) {
      for (final param in method.params!) {
        // Only register fallback if it's a custom type that might need it
        if (param.type.isCustomType) {
          buffer.writeln(
            '    registerFallbackValue(t${param.name.upperCamelCase});',
          );
        }
      }
    }
    buffer.writeln('  });');
  }

  void _generateActualTest(
    StringBuffer buffer,
    String className,
    IFunction method,
    List<String> testNames,
    dynamic resultValue, // The code string for the result
  ) {
    final returnType = method.returnType; // Raw return type
    final methodName = method.name;
    final isStream = returnType.startsWith('Stream');
    final rightType = returnType.rightType; // The success type

    buffer
      ..writeln('  test(')
      ..writeln("    'should call the [$className.$methodName]',")
      ..writeln('    () async {')
      // WHEN BLOCK
      ..writeln('      when(() => repo.$methodName(');
    if (method.params != null) {
      for (final param in method.params!) {
        final matcher = param.isNamed
            ? '${param.name}: any(named: "${param.name}"),'
            : 'any(),';
        buffer.writeln('        $matcher');
      }
    }
    buffer.writeln('      )).thenAnswer(');

    // ANSWER BLOCK
    final responsePayload = resultValue == 'null' ? 'null' : 'tResult';
    final prefix = isStream ? 'Stream.value(' : '';
    final suffix = isStream ? ')' : '';
    var modifier = (resultValue == 'null') ? '' : 'const';
    // If tResult is used (variable), remove const
    if (responsePayload == 'tResult') modifier = '';

    // Wrap in Right/Left. clean architecture assumes success path for this basic test.
    buffer
      ..writeln(
        '        (_) async => $prefix$modifier Right($responsePayload)$suffix,',
      )
      ..writeln('      );') // Close thenAnswer
      ..writeln();

    // ACT BLOCK
    final resultVar = isStream ? 'stream' : 'result';
    final awaitKey = isStream ? '' : 'await';

    // Handle Params Call
    var paramsCall = '()';
    if (testNames.length > 1) {
      // Assuming you have a Params class for multiple args
      // (UseCase specific pattern)
      final paramsClassName = '${method.name.upperCamelCase}Params';
      // We need to construct the params object
      final args = testNames
          .map((t) {
            final paramName = t.replaceFirst('t', '').lowerCamelCase;
            return '$paramName: $t';
          })
          .join(', ');
      paramsCall = '($paramsClassName($args))';
    } else if (testNames.isNotEmpty) {
      paramsCall = '(${testNames.first})';
    }

    buffer.writeln('      final $resultVar = $awaitKey usecase$paramsCall;');

    // ASSERT BLOCK
    final expectMatcher = isStream ? 'emits' : 'equals';
    buffer
      ..writeln('      expect(')
      ..writeln('        $resultVar,')
      ..writeln(
        '        $expectMatcher($modifier Right<dynamic, '
        '$rightType>($responsePayload)),',
      )
      ..writeln('      );')
      // VERIFY BLOCK
      ..writeln('      verify(() => repo.$methodName(');
    if (method.params != null) {
      for (final param in method.params!) {
        final matcher = param.isNamed
            ? '${param.name}: any(named: "${param.name}"),'
            : 'any(),';
        buffer.writeln('        $matcher');
      }
    }
    buffer
      ..writeln('      )).called(1);')
      ..writeln('      verifyNoMoreInteractions(repo);')
      ..writeln('    },')
      ..writeln('  );');
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

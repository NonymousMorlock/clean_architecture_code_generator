// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating an Adapter (Cubit/Bloc classes) from repository
/// annotations.
///
/// Processes classes annotated with `@AdapterGenAnnotation` and generates
/// corresponding Adapter classes for the interface adapter.
class AdapterGenerator extends GeneratorForAnnotation<AdapterGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    // Load config to check if multi-file output is enabled
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final writer = FeatureFileWriter(config, buildStep);

    // Debug: Write to log file
    try {
      File('/tmp/adapter_gen_debug.log').writeAsStringSync(
        'isMultiFileEnabled: ${writer.isMultiFileEnabled}\n'
        'config.multiFileOutput.enabled: ${config.multiFileOutput.enabled}\n'
        'inputPath: ${buildStep.inputId.path}\n',
        mode: FileMode.append,
      );
    } on Exception catch (_) {
      // Ignore
    }

    if (writer.isMultiFileEnabled) {
      return _generateMultiFile(visitor, writer, buildStep);
    }

    // Default behavior: generate to .g.dart
    final buffer = StringBuffer();

    // Generate Adapter
    _generateAdapter(
      buffer: buffer,
      visitor: visitor,
      isMultiMode: writer.isMultiFileEnabled,
    );

    // Generate States
    _generateStates(
      buffer: buffer,
      visitor: visitor,
      isMultiMode: writer.isMultiFileEnabled,
    );

    return buffer.toString();
  }

  String _generateMultiFile(
    RepoVisitor visitor,
    FeatureFileWriter writer,
    BuildStep buildStep,
  ) {
    final featureName = writer.extractFeatureName(repoName: visitor.className);
    stdout
      ..writeln('[AdapterGenerator] Input path: ${buildStep.inputId.path}')
      ..writeln('[AdapterGenerator] Extracted feature name: $featureName');

    if (featureName == null) {
      stdout.writeln(
        '[AdapterGenerator] Feature name is null, falling back to '
        'default generation',
      );
      // Fallback to default if feature name can't be extracted
      final buffer = StringBuffer();
      _generateAdapter(
        buffer: buffer,
        visitor: visitor,
        isMultiMode: writer.isMultiFileEnabled,
      );
      _generateStates(
        buffer: buffer,
        visitor: visitor,
        isMultiMode: writer.isMultiFileEnabled,
      );
      return buffer.toString();
    }

    final className = visitor.className;
    final baseName = className
        .replaceAll('CubitTBG', '')
        .replaceAll('Cubit', '')
        .replaceAll('AdapterTBG', '')
        .replaceAll('Adapter', '')
        .replaceAll('RepoTBG', '')
        .replaceAll('Repo', '');

    // Generate adapter file
    final adapterBuffer = StringBuffer();
    _generateAdapterBody(adapterBuffer, visitor);

    final adapterPath =
        '${writer.getFeatureRoot(featureName)}/presentation/adapter/${baseName.snakeCase}_adapter.dart';

    final importsBuffer = StringBuffer();
    _generateAdapterImports(
      buffer: importsBuffer,
      visitor: visitor,
      isMultiMode: writer.isMultiFileEnabled,
      featureName: featureName,
    );
    final adapterImports = [
      "import 'package:bloc/bloc.dart';",
      "import 'package:equatable/equatable.dart';",
      "import 'package:${writer.config.appName}/core/errors/failures.dart';",
      ...importsBuffer.toString().split('\n'),
    ];
    final completeAdapter = writer.generateCompleteFile(
      imports: adapterImports,
      generatedCode: adapterBuffer.toString(),
    );

    // Generate state file
    final stateBuffer = StringBuffer();
    _generateStatesImport(
      buffer: stateBuffer,
      isMultiMode: writer.isMultiFileEnabled,
      featureName: featureName,
    );
    stateBuffer.writeln();
    _generateStatesBody(stateBuffer, visitor);

    final statePath =
        '${writer.getFeatureRoot(featureName)}/presentation/adapter/${baseName.snakeCase}_state.dart';

    final completeState = writer.generateCompleteFile(
      generatedCode: stateBuffer.toString(),
    );

    // Write to actual files
    stdout
      ..writeln('[AdapterGenerator] Writing adapter to: $adapterPath')
      ..writeln('[AdapterGenerator] Writing state to: $statePath');

    try {
      File(adapterPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(completeAdapter);

      File(statePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(completeState);

      stdout.writeln('[AdapterGenerator] Successfully wrote files');
    } on Exception catch (e) {
      stderr
        ..writeln('[AdapterGenerator] ERROR: Could not write adapter files: $e')
        ..writeln('[AdapterGenerator] Stack trace: ${StackTrace.current}');
    }

    // Return minimal marker for .g.dart file
    return '''
// Adapter written to: $adapterPath
// State written to: $statePath
''';
  }

  void _generateAdapter({
    required StringBuffer buffer,
    required RepoVisitor visitor,
    required bool isMultiMode,
  }) {
    final className = visitor.className;
    final featureName = className
        .replaceAll('CubitTBG', '')
        .replaceAll('Cubit', '')
        .replaceAll('AdapterTBG', '')
        .replaceAll('Adapter', '');

    buffer
      ..writeln(
        '// **************************************************************************',
      )
      ..writeln('// AdapterGenerator - $featureName Adapter')
      ..writeln(
        '// **************************************************************************',
      )
      ..writeln()
      ..writeln("import 'package:bloc/bloc.dart';")
      ..writeln(
        "import 'package:equatable/equatable.dart';",
      );

    _generateAdapterImports(
      buffer: buffer,
      visitor: visitor,
      isMultiMode: isMultiMode,
      featureName: featureName,
    );

    _generateAdapterBody(buffer, visitor);
  }

  void _generateAdapterImports({
    required StringBuffer buffer,
    required RepoVisitor visitor,
    required bool isMultiMode,
    required String featureName,
  }) {
    // Import use cases
    for (final method in visitor.methods) {
      final usecaseFile = method.name.snakeCase;
      buffer.writeln("import '../../domain/usecases/$usecaseFile.dart';");
    }

    final optionalPartComment = isMultiMode ? '' : '// ';

    buffer
      ..writeln()
      ..writeln(
        "${optionalPartComment}part '${featureName.snakeCase}_state.dart';",
      );
  }

  void _generateAdapterBody(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    final featureName = className
        .replaceAll('CubitTBG', '')
        .replaceAll('Cubit', '')
        .replaceAll('AdapterTBG', '')
        .replaceAll('Adapter', '');
    final adapterName = '${featureName}Adapter';
    final stateName = '${featureName}State';

    buffer
      ..writeln('class $adapterName extends Cubit<$stateName> {')
      ..writeln('  $adapterName({');

    // Add use cases as constructor parameters
    for (final method in visitor.methods) {
      final usecaseName = method.name.upperCamelCase;
      final paramName = method.name.camelCase;
      buffer.writeln('    required $usecaseName $paramName,');
    }

    buffer.writeln('  }) : ');

    // Initialize private fields
    for (var i = 0; i < visitor.methods.length; i++) {
      final method = visitor.methods[i];
      final paramName = method.name.camelCase;
      final isLast = i == visitor.methods.length - 1;
      buffer.writeln('       _$paramName = $paramName${isLast ? ',' : ','}');
    }

    buffer
      ..writeln('       super(const ${featureName}Initial());')
      ..writeln();

    // Add private fields
    for (final method in visitor.methods) {
      final usecaseName = method.name.upperCamelCase;
      final paramName = method.name.camelCase;
      buffer.writeln('  final $usecaseName _$paramName;');
    }

    buffer.writeln();

    // Generate methods for each use case
    for (final method in visitor.methods) {
      _generateAdapterMethod(buffer, method, featureName);
    }

    buffer
      ..writeln('}')
      ..writeln();
  }

  void _generateAdapterMethod(
    StringBuffer buffer,
    IFunction method,
    String featureName,
  ) {
    final methodName = method.name;
    final usecasePrivateName = '_${methodName.camelCase}';
    final returnType = method.returnType.rightType;
    final isStream = method.returnType.startsWith('Stream');

    // Generate method signature
    if (method.params != null && method.params!.isNotEmpty) {
      // Method with parameters
      if (method.params!.length == 1) {
        final param = method.params![0];
        buffer.writeln(
          '  Future<void> $methodName(${param.type} ${param.name}) async {',
        );
      } else {
        // Multiple parameters - use params class
        final paramsClassName = '${methodName.upperCamelCase}Params';
        buffer.writeln(
          '  Future<void> $methodName($paramsClassName params) async {',
        );
      }
    } else {
      // Method without parameters
      buffer.writeln('  Future<void> $methodName() async {');
    }

    // Emit loading state
    if (isStream) {
      buffer
        ..writeln(
          '    // Note: Stream methods might need different handling',
        )
        ..writeln(
          '    // Consider using StreamSubscription for proper state management',
        );
    }

    // Special loading states for specific operations
    if (methodName.toLowerCase().contains('get') &&
        (methodName.toLowerCase().contains('page') ||
            methodName.toLowerCase().contains('first'))) {
      buffer
        ..writeln('    if (page == null || page == 1) {')
        ..writeln('      emit(const FirstPageLoading());')
        ..writeln('    } else {')
        ..writeln('      emit(const ${featureName}Loading());')
        ..writeln('    }');
    } else if (methodName.toLowerCase().contains('fetch') ||
        methodName.toLowerCase().contains('get')) {
      if (methodName.toLowerCase().contains('id') ||
          methodName.toLowerCase().contains('single')) {
        buffer.writeln('    emit(const Fetching$featureName());');
      } else {
        buffer.writeln('    emit(const ${featureName}Loading());');
      }
    } else if (methodName.toLowerCase().contains('updat')) {
      buffer.writeln('    emit(const Updating$featureName());');
    } else {
      buffer.writeln('    emit(const ${featureName}Loading());');
    }

    buffer.writeln();

    // Call use case
    if (method.params != null && method.params!.isNotEmpty) {
      if (method.params!.length == 1) {
        final param = method.params![0];
        buffer.writeln(
          '    final result = await $usecasePrivateName(${param.name});',
        );
      } else {
        buffer.writeln('    final result = await $usecasePrivateName(params);');
      }
    } else {
      buffer.writeln('    final result = await $usecasePrivateName();');
    }

    buffer
      ..writeln()
      // Handle result
      ..writeln('    result.fold(')
      ..writeln(
        '      (failure) => emit(${featureName}Error.fromFailure(failure)),',
      );

    // Generate success state based on method name and return type
    final successState = _generateSuccessState(
      methodName,
      returnType,
      featureName,
    );
    if (returnType.toLowerCase().trim() == 'void') {
      buffer.writeln('      (_) => emit(const $successState()),');
    } else {
      final paramName = returnType.toLowerCase().startsWith('list')
          ? 'data'
          : returnType.camelCase;
      buffer.writeln('      ($paramName) => emit($successState($paramName)),');
    }

    buffer
      ..writeln('    );')
      ..writeln('  }')
      ..writeln();
  }

  String _generateSuccessState(
    String methodName,
    String returnType,
    String featureName,
  ) {
    final method = methodName.toLowerCase();

    if (method.contains('create')) {
      return '${featureName}Created';
    } else if (method.contains('delete')) {
      return '${featureName}Deleted';
    } else if (method.contains('update')) {
      return '${featureName}Updated';
    } else if (method.contains('restore')) {
      return '${featureName}Restored';
    } else if (method.contains('feature')) {
      return '${featureName}Featured';
    } else if (method.contains('unfeature')) {
      return '${featureName}Unfeatured';
    } else if (method.contains('replace')) {
      return '${featureName}Replaced';
    } else if (method.contains('add') && method.contains('image')) {
      return 'ImagesAddedToGallery';
    } else if (method.contains('remove') && method.contains('image')) {
      return 'ImagesRemovedFromGallery';
    } else if (method.contains('reorder') && method.contains('image')) {
      return 'ImagesReorderedInGallery';
    } else if (method.contains('count')) {
      return '${featureName}CountsLoaded';
    } else if (method.contains('recent')) {
      return 'RecentlyUpdated${featureName}sLoaded';
    } else if (returnType.toLowerCase().startsWith('list')) {
      return '${featureName}sLoaded';
    } else {
      return '${featureName}Loaded';
    }
  }

  void _generateStates({
    required StringBuffer buffer,
    required RepoVisitor visitor,
    required bool isMultiMode,
  }) {
    final className = visitor.className;
    final featureName = className
        .replaceAll('CubitTBG', '')
        .replaceAll('Cubit', '')
        .replaceAll('AdapterTBG', '')
        .replaceAll('Adapter', '');

    buffer
      ..writeln(
        '// **************************************************************************',
      )
      ..writeln('// StateGenerator - $featureName States')
      ..writeln(
        '// **************************************************************************',
      )
      ..writeln();

    _generateStatesImport(
      buffer: buffer,
      isMultiMode: isMultiMode,
      featureName: featureName,
    );
    _generateStatesBody(buffer, visitor);
  }

  void _generateStatesImport({
    required StringBuffer buffer,
    required bool isMultiMode,
    required String featureName,
  }) {
    final optionalPartComment = isMultiMode ? '' : '// ';

    buffer.writeln(
      "${optionalPartComment}part of '${featureName.snakeCase}_adapter.dart';",
    );
  }

  void _generateStatesBody(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    final featureName = className
        .replaceAll('CubitTBG', '')
        .replaceAll('Cubit', '')
        .replaceAll('AdapterTBG', '')
        .replaceAll('Adapter', '');
    final stateName = '${featureName}State';

    buffer
      ..writeln('sealed class $stateName extends Equatable {')
      ..writeln('  const $stateName();')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  List<Object> get props => [];')
      ..writeln('}')
      ..writeln()
      // Initial state
      ..writeln('final class ${featureName}Initial extends $stateName {')
      ..writeln('  const ${featureName}Initial();')
      ..writeln('}')
      ..writeln()
      // Loading states
      ..writeln('final class ${featureName}Loading extends $stateName {')
      ..writeln('  const ${featureName}Loading();')
      ..writeln('}')
      ..writeln()
      ..writeln(
        'final class FirstPageLoading extends ${featureName}Loading {',
      )
      ..writeln('  const FirstPageLoading();')
      ..writeln('}')
      ..writeln()
      ..writeln(
        'final class Fetching$featureName extends ${featureName}Loading {',
      )
      ..writeln('  const Fetching$featureName();')
      ..writeln('}')
      ..writeln()
      ..writeln(
        'final class Updating$featureName extends ${featureName}Loading {',
      )
      ..writeln('  const Updating$featureName();')
      ..writeln('}')
      ..writeln();

    // Generate success states based on methods
    final generatedStates = <String>{};

    for (final method in visitor.methods) {
      final returnType = method.returnType.rightType;
      final successState = _generateSuccessState(
        method.name,
        returnType,
        featureName,
      );

      if (!generatedStates.contains(successState)) {
        generatedStates.add(successState);
        _generateSuccessStateClass(buffer, successState, returnType, stateName);
      }
    }

    // Error state
    buffer
      ..writeln('final class ${featureName}Error extends $stateName {')
      ..writeln(
        '  const ${featureName}Error({required this.message, '
        'required this.title});',
      )
      ..writeln()
      ..writeln('  ${featureName}Error.fromFailure(Failure failure)')
      ..writeln(
        "    : this(message: failure.message, title: 'Error "
        r"${failure.statusCode}');",
      )
      ..writeln()
      ..writeln('  final String message;')
      ..writeln('  final String title;')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  List<String> get props => [message, title];')
      ..writeln('}')
      ..writeln()
      // Specialized error states
      ..writeln(
        'final class Paginated${featureName}sFetchError extends '
        '${featureName}Error {',
      )
      ..writeln('  const Paginated${featureName}sFetchError({')
      ..writeln('    required super.message,')
      ..writeln('    required super.title,')
      ..writeln('  });')
      ..writeln()
      ..writeln(
        '  Paginated${featureName}sFetchError.fromFailure(Failure failure)',
      )
      ..writeln(
        "    : this(message: failure.message, title: 'Error "
        r"${failure.statusCode}');",
      )
      ..writeln('}');
  }

  void _generateSuccessStateClass(
    StringBuffer buffer,
    String stateName,
    String returnType,
    String baseStateName,
  ) {
    buffer.writeln('final class $stateName extends $baseStateName {');

    if (returnType.toLowerCase().trim() == 'void') {
      buffer.writeln('  const $stateName();');
    } else {
      final paramName = returnType.toLowerCase().startsWith('list')
          ? 'data'
          : returnType.camelCase;
      buffer
        ..writeln('  const $stateName(this.$paramName);')
        ..writeln()
        ..writeln('  final $returnType $paramName;')
        ..writeln()
        ..writeln('  @override');
      if (returnType.toLowerCase().startsWith('list')) {
        buffer.writeln('  List<Object> get props => $paramName;');
      } else {
        buffer.writeln('  List<Object> get props => [$paramName];');
      }
    }

    buffer
      ..writeln('}')
      ..writeln();
  }
}

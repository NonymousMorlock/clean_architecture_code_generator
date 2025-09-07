// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

class CubitGenerator extends GeneratorForAnnotation<CubitGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();
    
    // Generate Cubit
    _generateCubit(buffer, visitor);
    
    // Generate States
    _generateStates(buffer, visitor);
    
    return buffer.toString();
  }

  void _generateCubit(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    final featureName = className.replaceAll('CubitTBG', '').replaceAll('Cubit', '');
    final cubitName = '${featureName}Cubit';
    final stateName = '${featureName}State';
    
    buffer.writeln('// **************************************************************************');
    buffer.writeln('// CubitGenerator - $featureName Cubit');
    buffer.writeln('// **************************************************************************');
    buffer.writeln();
    buffer.writeln('import \'package:bloc/bloc.dart\';');
    buffer.writeln('import \'package:equatable/equatable.dart\';');
    
    // Import use cases
    for (final method in visitor.methods) {
      final usecaseName = method.name.upperCamelCase;
      final usecaseFile = method.name.snakeCase;
      buffer.writeln('import \'../../domain/usecases/$usecaseFile.dart\';');
    }
    
    buffer.writeln();
    buffer.writeln('part \'${featureName.snakeCase}_state.dart\';');
    buffer.writeln();
    buffer.writeln('class $cubitName extends Cubit<$stateName> {');
    buffer.writeln('  $cubitName({');
    
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
      final usecaseName = method.name.upperCamelCase;
      final paramName = method.name.camelCase;
      final isLast = i == visitor.methods.length - 1;
      buffer.writeln('       _$paramName = $paramName${isLast ? ',' : ','}');
    }
    
    buffer.writeln('       super(const ${featureName}Initial());');
    buffer.writeln();
    
    // Add private fields
    for (final method in visitor.methods) {
      final usecaseName = method.name.upperCamelCase;
      final paramName = method.name.camelCase;
      buffer.writeln('  final $usecaseName _$paramName;');
    }
    
    buffer.writeln();
    
    // Generate methods for each use case
    for (final method in visitor.methods) {
      _generateCubitMethod(buffer, method, featureName);
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }

  void _generateCubitMethod(StringBuffer buffer, dynamic method, String featureName) {
    final methodName = method.name;
    final usecasePrivateName = '_${methodName.camelCase}';
    final returnType = method.returnType.rightType;
    final isStream = method.returnType.startsWith('Stream');
    
    // Generate method signature
    if (method.params != null && method.params!.isNotEmpty) {
      // Method with parameters
      if (method.params!.length == 1) {
        final param = method.params![0];
        buffer.writeln('  Future<void> $methodName(${param.type} ${param.name}) async {');
      } else {
        // Multiple parameters - use params class
        final paramsClassName = '${methodName.upperCamelCase}Params';
        buffer.writeln('  Future<void> $methodName($paramsClassName params) async {');
      }
    } else {
      // Method without parameters
      buffer.writeln('  Future<void> $methodName() async {');
    }
    
    // Emit loading state
    if (isStream) {
      buffer.writeln('    // Note: Stream methods might need different handling');
      buffer.writeln('    // Consider using StreamSubscription for proper state management');
    }
    
    // Special loading states for specific operations
    if (methodName.toLowerCase().contains('get') && 
        (methodName.toLowerCase().contains('page') || methodName.toLowerCase().contains('first'))) {
      buffer.writeln('    if (page == null || page == 1) {');
      buffer.writeln('      emit(const FirstPageLoading());');
      buffer.writeln('    } else {');
      buffer.writeln('      emit(const ${featureName}Loading());');
      buffer.writeln('    }');
    } else if (methodName.toLowerCase().contains('fetch') || methodName.toLowerCase().contains('get')) {
      if (methodName.toLowerCase().contains('id') || methodName.toLowerCase().contains('single')) {
        buffer.writeln('    emit(const Fetching${featureName}());');
      } else {
        buffer.writeln('    emit(const ${featureName}Loading());');
      }
    } else if (methodName.toLowerCase().contains('updat')) {
      buffer.writeln('    emit(const Updating${featureName}());');
    } else {
      buffer.writeln('    emit(const ${featureName}Loading());');
    }
    
    buffer.writeln();
    
    // Call use case
    if (method.params != null && method.params!.isNotEmpty) {
      if (method.params!.length == 1) {
        final param = method.params![0];
        buffer.writeln('    final result = await $usecasePrivateName(${param.name});');
      } else {
        buffer.writeln('    final result = await $usecasePrivateName(params);');
      }
    } else {
      buffer.writeln('    final result = await $usecasePrivateName();');
    }
    
    buffer.writeln();
    
    // Handle result
    buffer.writeln('    result.fold(');
    buffer.writeln('      (failure) => emit(${featureName}Error.fromFailure(failure)),');
    
    // Generate success state based on method name and return type
    final successState = _generateSuccessState(methodName, returnType, featureName);
    if (returnType.toLowerCase().trim() == 'void') {
      buffer.writeln('      (_) => emit(const $successState()),');
    } else {
      buffer.writeln('      (${returnType.toLowerCase().startsWith('list') ? 'data' : returnType.camelCase}) => emit($successState(${returnType.toLowerCase().startsWith('list') ? 'data' : returnType.camelCase})),');
    }
    
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
  }

  String _generateSuccessState(String methodName, String returnType, String featureName) {
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

  void _generateStates(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    final featureName = className.replaceAll('CubitTBG', '').replaceAll('Cubit', '');
    final stateName = '${featureName}State';
    
    buffer.writeln('// **************************************************************************');
    buffer.writeln('// StateGenerator - $featureName States');
    buffer.writeln('// **************************************************************************');
    buffer.writeln();
    buffer.writeln('part of \'${featureName.snakeCase}_cubit.dart\';');
    buffer.writeln();
    buffer.writeln('sealed class $stateName extends Equatable {');
    buffer.writeln('  const $stateName();');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  List<Object> get props => [];');
    buffer.writeln('}');
    buffer.writeln();
    
    // Initial state
    buffer.writeln('final class ${featureName}Initial extends $stateName {');
    buffer.writeln('  const ${featureName}Initial();');
    buffer.writeln('}');
    buffer.writeln();
    
    // Loading states
    buffer.writeln('final class ${featureName}Loading extends $stateName {');
    buffer.writeln('  const ${featureName}Loading();');
    buffer.writeln('}');
    buffer.writeln();
    
    buffer.writeln('final class FirstPageLoading extends ${featureName}Loading {');
    buffer.writeln('  const FirstPageLoading();');
    buffer.writeln('}');
    buffer.writeln();
    
    buffer.writeln('final class Fetching${featureName} extends ${featureName}Loading {');
    buffer.writeln('  const Fetching${featureName}();');
    buffer.writeln('}');
    buffer.writeln();
    
    buffer.writeln('final class Updating${featureName} extends ${featureName}Loading {');
    buffer.writeln('  const Updating${featureName}();');
    buffer.writeln('}');
    buffer.writeln();
    
    // Generate success states based on methods
    final generatedStates = <String>{};
    
    for (final method in visitor.methods) {
      final returnType = method.returnType.rightType;
      final successState = _generateSuccessState(method.name, returnType, featureName);
      
      if (!generatedStates.contains(successState)) {
        generatedStates.add(successState);
        _generateSuccessStateClass(buffer, successState, returnType, stateName);
      }
    }
    
    // Error state
    buffer.writeln('final class ${featureName}Error extends $stateName {');
    buffer.writeln('  const ${featureName}Error({required this.message, required this.title});');
    buffer.writeln();
    buffer.writeln('  ${featureName}Error.fromFailure(Failure failure)');
    buffer.writeln('    : this(message: failure.message, title: \'Error \${failure.statusCode}\');');
    buffer.writeln();
    buffer.writeln('  final String message;');
    buffer.writeln('  final String title;');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  List<String> get props => [message, title];');
    buffer.writeln('}');
    buffer.writeln();
    
    // Specialized error states
    buffer.writeln('final class Paginated${featureName}sFetchError extends ${featureName}Error {');
    buffer.writeln('  const Paginated${featureName}sFetchError({');
    buffer.writeln('    required super.message,');
    buffer.writeln('    required super.title,');
    buffer.writeln('  });');
    buffer.writeln();
    buffer.writeln('  Paginated${featureName}sFetchError.fromFailure(Failure failure)');
    buffer.writeln('    : this(message: failure.message, title: \'Error \${failure.statusCode}\');');
    buffer.writeln('}');
  }

  void _generateSuccessStateClass(StringBuffer buffer, String stateName, String returnType, String baseStateName) {
    buffer.writeln('final class $stateName extends $baseStateName {');
    
    if (returnType.toLowerCase().trim() == 'void') {
      buffer.writeln('  const $stateName();');
    } else {
      final paramName = returnType.toLowerCase().startsWith('list') ? 'data' : returnType.camelCase;
      buffer.writeln('  const $stateName(this.$paramName);');
      buffer.writeln();
      buffer.writeln('  final $returnType $paramName;');
      buffer.writeln();
      buffer.writeln('  @override');
      if (returnType.toLowerCase().startsWith('list')) {
        buffer.writeln('  List<Object> get props => $paramName;');
      } else {
        buffer.writeln('  List<Object> get props => [$paramName];');
      }
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }
}

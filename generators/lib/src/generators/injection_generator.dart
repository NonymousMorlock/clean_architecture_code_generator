// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating dependency injection container code.
///
/// Processes classes annotated with `@InjectionGenAnnotation` and generates
/// dependency injection setup code for the application.
class InjectionGenerator
    extends GeneratorForAnnotation<InjectionGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    final buffer = StringBuffer();

    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

    // Generate injection container base file content
    _generateInjectionContainerBase(
      buffer: buffer,
      isMultiMode: config.multiFileOutput.enabled,
    );

    // Generate injection container main file content
    _generateInjectionContainerMain(
      buffer: buffer,
      visitor: visitor,
      isMultiMode: config.multiFileOutput.enabled,
    );

    return buffer.toString();
  }

  void _generateInjectionContainerBase({
    required StringBuffer buffer,
    required bool isMultiMode,
  }) {
    final optionalPartComment = isMultiMode ? '' : '// ';
    buffer
      ..writeln('// Generated injection container base file')
      ..writeln(
        '// This file contains all imports for the injection container',
      )
      ..writeln(
        '// It is automatically updated when new dependencies are added',
      )
      ..writeln()
      ..writeln('library injection_container;')
      ..writeln()
      ..writeln("import 'package:get_it/get_it.dart';")
      ..writeln(
        "import 'package:shared_preferences/shared_preferences.dart';",
      )
      ..writeln("import 'package:dio/dio.dart';")
      ..writeln()
      ..writeln('// TODO: Add additional imports here as needed')
      ..writeln(
        '// These imports will be automatically managed by the generator',
      )
      ..writeln()
      ..writeln("${optionalPartComment}part 'injection_container.main.dart';")
      ..writeln();
  }

  void _generateInjectionContainerMain({
    required StringBuffer buffer,
    required RepoVisitor visitor,
    required bool isMultiMode,
  }) {
    final className = visitor.className;
    final featureName = className
        .replaceAll('RepoTBG', '')
        .replaceAll('Repo', '');
    final optionalPartComment = isMultiMode ? '' : '// ';

    buffer
      ..writeln(
        '// **************************************************************************',
      )
      ..writeln('// InjectionGenerator - $featureName Module')
      ..writeln(
        '// **************************************************************************',
      )
      ..writeln()
      ..writeln("${optionalPartComment}part of 'injection_container.dart';")
      ..writeln()
      ..writeln('final sl = GetIt.instance;')
      ..writeln()
      ..writeln('Future<void> init() async {')
      ..writeln('  await _initServices();')
      ..writeln('  await _init$featureName();')
      ..writeln('}')
      ..writeln();

    // Generate feature-specific initialization
    _generateFeatureInit(buffer, visitor, featureName);

    // Generate services initialization
    _generateServicesInit(buffer);
  }

  void _generateFeatureInit(
    StringBuffer buffer,
    RepoVisitor visitor,
    String featureName,
  ) {
    final className = visitor.className;
    final repoName = className.replaceAll('TBG', '');
    final cubitName = '${featureName}Cubit';

    buffer
      ..writeln('Future<void> _init$featureName() async {')
      ..writeln('  sl')
      // Register Cubit/BLoC (factory)
      ..writeln('    ..registerFactory(() {')
      ..writeln('      return $cubitName(');

    // Add use cases as named parameters
    for (final method in visitor.methods) {
      final paramName = method.name.camelCase;
      buffer.writeln('        $paramName: sl(),');
    }

    buffer
      ..writeln('      );')
      ..writeln('    })');

    // Register Use Cases (lazy singletons)
    for (final method in visitor.methods) {
      final usecaseName = method.name.upperCamelCase;
      buffer.writeln('    ..registerLazySingleton(() => $usecaseName(sl()))');
    }

    // Register Repository Implementation (lazy singleton)
    final repoImplName = '${repoName}Impl';
    buffer.writeln(
      '    ..registerLazySingleton<$repoName>(() => $repoImplName(sl(), sl()))',
    );

    // Register Remote Data Source (lazy singleton)
    final remoteSrcName = '${featureName}RemoteDataSrc';
    final remoteSrcImplName = '${remoteSrcName}Impl';
    buffer
      ..writeln('    ..registerLazySingleton<$remoteSrcName>(')
      ..writeln('      () => $remoteSrcImplName(sl()),')
      ..writeln('    )');

    // Register Local Data Source (lazy singleton)
    final localSrcName = '${featureName}LocalDataSrc';
    final localSrcImplName = '${localSrcName}Impl';
    buffer
      ..writeln('    ..registerLazySingleton<$localSrcName>(')
      ..writeln('      () => $localSrcImplName(sl()),')
      ..writeln('    );')
      ..writeln('}')
      ..writeln();
  }

  void _generateServicesInit(StringBuffer buffer) {
    buffer
      ..writeln('Future<void> _initServices() async {')
      ..writeln('  // Initialize core services')
      ..writeln(
        '  final sharedPreferences = await SharedPreferences.getInstance();',
      )
      ..writeln('  sl.registerLazySingleton(() => sharedPreferences);')
      ..writeln()
      ..writeln('  // Initialize Dio with base configuration')
      ..writeln('  final dioOptions = BaseOptions(')
      ..writeln("    contentType: 'application/json',")
      ..writeln('    // TODO: Add your base URL here')
      ..writeln('    // baseUrl: NetworkConstants.baseUrl,')
      ..writeln('  );')
      ..writeln('  final dio = Dio(dioOptions);')
      ..writeln('  ')
      ..writeln('  // Add interceptors')
      ..writeln('  dio.interceptors.addAll([')
      ..writeln(
        '    LogInterceptor(requestBody: true, responseBody: true),',
      )
      ..writeln('    // TODO: Add additional interceptors as needed')
      ..writeln(
        '    // RefreshTokenInterceptor(dio: dio, sessionBloc: sl<SessionBloc>()),',
      )
      ..writeln('  ]);')
      ..writeln('  ')
      ..writeln('  sl.registerLazySingleton(() => dio);')
      ..writeln('}');
  }
}

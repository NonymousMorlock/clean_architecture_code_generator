// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

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

    // Generate injection container base file content
    _generateInjectionContainerBase(buffer);

    // Generate injection container main file content
    _generateInjectionContainerMain(buffer, visitor);

    return buffer.toString();
  }

  void _generateInjectionContainerBase(StringBuffer buffer) {
    buffer.writeln('// Generated injection container base file');
    buffer.writeln(
      '// This file contains all imports for the injection container',
    );
    buffer.writeln(
      '// It is automatically updated when new dependencies are added',
    );
    buffer.writeln();
    buffer.writeln('library injection_container;');
    buffer.writeln();
    buffer.writeln('import \'package:get_it/get_it.dart\';');
    buffer.writeln(
      'import \'package:shared_preferences/shared_preferences.dart\';',
    );
    buffer.writeln('import \'package:dio/dio.dart\';');
    buffer.writeln();
    buffer.writeln('// TODO: Add additional imports here as needed');
    buffer.writeln(
      '// These imports will be automatically managed by the generator',
    );
    buffer.writeln();
    buffer.writeln('part \'injection_container.main.dart\';');
    buffer.writeln();
  }

  void _generateInjectionContainerMain(
    StringBuffer buffer,
    RepoVisitor visitor,
  ) {
    final className = visitor.className;
    final featureName =
        className.replaceAll('RepoTBG', '').replaceAll('Repo', '');

    buffer.writeln(
      '// **************************************************************************',
    );
    buffer.writeln('// InjectionGenerator - $featureName Module');
    buffer.writeln(
      '// **************************************************************************',
    );
    buffer.writeln();
    buffer.writeln('part of \'injection_container.dart\';');
    buffer.writeln();
    buffer.writeln('final sl = GetIt.instance;');
    buffer.writeln();
    buffer.writeln('Future<void> init() async {');
    buffer.writeln('  await _initServices();');
    buffer.writeln('  await _init$featureName();');
    buffer.writeln('}');
    buffer.writeln();

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

    buffer.writeln('Future<void> _init$featureName() async {');
    buffer.writeln('  sl');

    // Register Cubit/BLoC (factory)
    buffer.writeln('    ..registerFactory(() {');
    buffer.writeln('      return $cubitName(');

    // Add use cases as named parameters
    for (final method in visitor.methods) {
      final usecaseName = method.name.upperCamelCase;
      final paramName = method.name.camelCase;
      buffer.writeln('        $paramName: sl(),');
    }

    buffer.writeln('      );');
    buffer.writeln('    })');

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
    buffer.writeln('    ..registerLazySingleton<$remoteSrcName>(');
    buffer.writeln('      () => $remoteSrcImplName(sl()),');
    buffer.writeln('    )');

    // Register Local Data Source (lazy singleton)
    final localSrcName = '${featureName}LocalDataSrc';
    final localSrcImplName = '${localSrcName}Impl';
    buffer.writeln('    ..registerLazySingleton<$localSrcName>(');
    buffer.writeln('      () => $localSrcImplName(sl()),');
    buffer.writeln('    );');

    buffer.writeln('}');
    buffer.writeln();
  }

  void _generateServicesInit(StringBuffer buffer) {
    buffer.writeln('Future<void> _initServices() async {');
    buffer.writeln('  // Initialize core services');
    buffer.writeln(
      '  final sharedPreferences = await SharedPreferences.getInstance();',
    );
    buffer.writeln('  sl.registerLazySingleton(() => sharedPreferences);');
    buffer.writeln();
    buffer.writeln('  // Initialize Dio with base configuration');
    buffer.writeln('  final dioOptions = BaseOptions(');
    buffer.writeln('    contentType: \'application/json\',');
    buffer.writeln('    // TODO: Add your base URL here');
    buffer.writeln('    // baseUrl: NetworkConstants.baseUrl,');
    buffer.writeln('  );');
    buffer.writeln('  final dio = Dio(dioOptions);');
    buffer.writeln('  ');
    buffer.writeln('  // Add interceptors');
    buffer.writeln('  dio.interceptors.addAll([');
    buffer.writeln(
      '    LogInterceptor(requestBody: true, responseBody: true),',
    );
    buffer.writeln('    // TODO: Add additional interceptors as needed');
    buffer.writeln(
      '    // RefreshTokenInterceptor(dio: dio, sessionBloc: sl<SessionBloc>()),',
    );
    buffer.writeln('  ]);');
    buffer.writeln('  ');
    buffer.writeln('  sl.registerLazySingleton(() => dio);');
    buffer.writeln('}');
  }
}

// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/extensions/repo_visitor_extensions.dart';
import 'package:generators/generators.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating remote data source classes from
/// repository annotations.
///
/// Processes classes annotated with `@RemoteDataSrcGenAnnotation` and generates
/// corresponding remote data source interfaces and implementations.
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

    // Load config to check if multi-file output is enabled
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final writer = FeatureFileWriter(config, buildStep);

    if (writer.isMultiFileEnabled) {
      return _generateMultiFile(visitor, writer, buildStep, config);
    }

    // Default behavior: generate to .g.dart
    final buffer = StringBuffer();
    remoteDataSource(buffer: buffer, visitor: visitor, handleImports: true);
    return buffer.toString();
  }

  String _generateMultiFile(
    RepoVisitor visitor,
    FeatureFileWriter writer,
    BuildStep buildStep,
    GeneratorConfig config,
  ) {
    final featureName = writer.extractFeatureName(repoName: visitor.className);
    if (featureName == null) {
      // Fallback to default
      final buffer = StringBuffer();
      remoteDataSource(buffer: buffer, visitor: visitor);
      return buffer.toString();
    }

    final baseName = writer.extractBaseName(visitor.className);
    final dataSourcePath = writer.getRemoteDataSrcPath(featureName, baseName);

    // Generate remote data source code
    final buffer = StringBuffer();
    remoteDataSource(buffer: buffer, visitor: visitor);

    // Generate complete file with imports
    final imports = writer.generateSmartRemoteDataSrcImports(
      candidates: visitor.discoverRequiredEntities(),
      featureName: featureName,
    );
    final completeFile = writer.generateCompleteFile(
      imports: imports,
      generatedCode: buffer.toString(),
    );

    // Write to the data source file
    try {
      writer.writeToFile(dataSourcePath, completeFile);
      // Return a minimal marker for the .g.dart file
      return '// Remote data source written to: $dataSourcePath\n';
    } on Exception catch (e) {
      stderr.writeln('Warning: Could not write to $dataSourcePath: $e');
      return '// Error: Could not write to $dataSourcePath: $e\n';
    }
  }

  /// Generates the remote data source interface and implementation.
  ///
  /// Creates both the abstract interface and concrete implementation class
  /// with HTTP client configuration based on the YAML config.
  void remoteDataSource({
    required StringBuffer buffer,
    required RepoVisitor visitor,
    bool handleImports = false,
  }) {
    final repoName = visitor.className;
    final dataSrcName =
        '${repoName.substring(0, repoName.length - 4)}RemoteDataSrc';

    // Load configuration for imports
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

    if (handleImports) {
      // Generate imports based on configuration
      _generateConfigBasedImports(buffer, config);
    }

    Utils.oneMemberAbstractHandler(
      buffer: buffer,
      methodLength: visitor.methods.length,
    );
    buffer
      ..writeln('abstract interface class $dataSrcName {')
      ..writeln('const $dataSrcName();')
      ..writeln();

    ({
      String asynchronyType,
      String? params,
      String returnType,
      String modifier,
    })
    initMethodGeneration({required IFunction method}) {
      var returnType = method.returnType.rightType;
      if (returnType.isCustomType) returnType = returnType.modelizeType;
      final isStream = method.returnType.startsWith('Stream');
      final asynchronyType = isStream ? 'Stream' : 'Future';
      final params = method.params
          ?.map((param) => paramToString(method, param))
          .join(', ');
      return (
        asynchronyType: asynchronyType,
        params: params,
        returnType: returnType,
        modifier: isStream ? '' : 'async',
      );
    }

    for (final method in visitor.methods) {
      final (
        asynchronyType: asynchronyType,
        params: params,
        returnType: returnType,
        modifier: _,
      ) = initMethodGeneration(
        method: method,
      );
      if (params != null) {
        buffer.writeln('$asynchronyType<$returnType> ${method.name}($params);');
      } else {
        buffer.writeln('$asynchronyType<$returnType> ${method.name}();');
      }
      buffer.writeln();
    }
    buffer
      ..writeln('}')
      ..writeln()
      ..writeln('class ${dataSrcName}Impl implements $dataSrcName {');

    // Load configuration instead of prompting user
    final remoteConfig = config.remoteDataSourceConfig;

    // Generate constructor based on YAML configuration
    _generateConfigBasedConstructor(buffer, dataSrcName, remoteConfig);

    buffer.writeln();
    for (final method in visitor.methods) {
      final (
        asynchronyType: asynchronyType,
        params: params,
        returnType: returnType,
        modifier: modifier,
      ) = initMethodGeneration(
        method: method,
      );
      if (params != null) {
        buffer
          ..writeln('@override')
          ..writeln(
            '$asynchronyType<$returnType> ${method.name}'
            '($params) $modifier {',
          );
        _generateMethodImplementation(buffer, method, remoteConfig);
        buffer
          ..writeln('}')
          ..writeln();
      } else {
        buffer
          ..writeln('@override')
          ..writeln(
            '$asynchronyType<$returnType> ${method.name}() '
            '$modifier {',
          );
        _generateMethodImplementation(buffer, method, remoteConfig);
        buffer
          ..writeln('}')
          ..writeln();
      }
    }
    buffer.writeln('}');
  }

  /// Prompts the user for yes/no input via terminal.
  ///
  /// Returns true if the user enters 'yes' or 'y', false otherwise.
  bool getTerminalInfo(String question) {
    stdout.write('$question (yes): ');
    final result = stdin.readLineSync() ?? 'yes';
    return !(result.isNotEmpty &&
        result.toLowerCase() != 'yes' &&
        result.toLowerCase() != 'y');
  }

  void _generateConfigBasedConstructor(
    StringBuffer buffer,
    String className,
    RemoteDataSourceConfig config,
  ) {
    final dependencies = config.constructorDependencies;

    if (dependencies.isEmpty) {
      buffer.writeln('const ${className}Impl();');
    } else if (dependencies.length == 1) {
      final dependency = dependencies.first;
      final parts = dependency.split(' ');
      final type = parts[0];
      final name = parts[1];
      buffer
        ..writeln('const ${className}Impl(this._$name);')
        ..writeln()
        ..writeln('final $type _$name;');
    } else {
      // Multiple dependencies
      buffer.writeln('const ${className}Impl({');
      for (final dependency in dependencies) {
        final parts = dependency.split(' ');
        final type = parts[0];
        final name = parts[1];
        buffer.writeln('required $type $name,');
      }
      buffer.writeln('}) : ');

      for (var i = 0; i < dependencies.length; i++) {
        final dependency = dependencies[i];
        final parts = dependency.split(' ');
        final name = parts[1];
        final isLast = i == dependencies.length - 1;
        buffer.writeln("_$name = $name${isLast ? ';' : ','}");
      }

      buffer.writeln();

      // Generate private fields
      for (final dependency in dependencies) {
        final parts = dependency.split(' ');
        final type = parts[0];
        final name = parts[1];
        buffer.writeln('final $type _$name;');
      }
    }
    buffer.writeln();
  }

  void _generateMethodImplementation(
    StringBuffer buffer,
    IFunction method,
    RemoteDataSourceConfig config,
  ) {
    buffer.writeln('\t// TODO(${method.name}): implement ${method.name}');

    // Add configuration-aware implementation hints
    if (config.useFirebaseFirestore &&
        method.name.toLowerCase().contains('get')) {
      buffer.writeln(
        "\t// Hint: Use _firestore.collection('...').get() for Firestore",
      );
    } else if (config.useFirebaseAuth &&
        method.name.toLowerCase().contains('auth')) {
      buffer.writeln(
        '\t// Hint: Use _firebaseAuth.signInWithEmailAndPassword() for auth',
      );
    } else if (config.useGraphQL &&
        (method.name.toLowerCase().contains('get') ||
            method.name.toLowerCase().contains('fetch'))) {
      buffer.writeln(
        '\t// Hint: Use _graphQLClient.query() for GraphQL queries',
      );
    } else if (config.useWebSockets &&
        method.name.toLowerCase().contains('stream')) {
      buffer.writeln(
        '\t// Hint: Use _webSocketChannel.stream for WebSocket streams',
      );
    } else if (config.useSupabase) {
      if (method.name.toLowerCase().contains('get')) {
        buffer.writeln(
          "\t// Hint: Use _supabaseClient.from('table').select() for Supabase queries",
        );
      } else if (method.name.toLowerCase().contains('create') ||
          method.name.toLowerCase().contains('insert')) {
        buffer.writeln(
          "\t// Hint: Use _supabaseClient.from('table').insert() for Supabase inserts",
        );
      }
    } else {
      // Default HTTP implementation hint
      switch (config.httpClient) {
        case HttpClientType.dio:
          if (method.name.toLowerCase().contains('get')) {
            buffer.writeln(
              "\t// Hint: Use _dio.get('/endpoint') for GET requests",
            );
          } else if (method.name.toLowerCase().contains('post') ||
              method.name.toLowerCase().contains('create')) {
            buffer.writeln(
              "\t// Hint: Use _dio.post('/endpoint', data: data) for POST requests",
            );
          } else if (method.name.toLowerCase().contains('put') ||
              method.name.toLowerCase().contains('update')) {
            buffer.writeln(
              "\t// Hint: Use _dio.put('/endpoint', data: data) for PUT requests",
            );
          } else if (method.name.toLowerCase().contains('delete')) {
            buffer.writeln(
              "\t// Hint: Use _dio.delete('/endpoint') for DELETE requests",
            );
          }
        case HttpClientType.http:
          buffer.writeln(
            "\t// Hint: Use _client.get(Uri.parse('url')) for HTTP requests",
          );
        case HttpClientType.chopper:
          buffer.writeln(
            '\t// Hint: Use _client.getService<ApiService>().method() for Chopper',
          );
        case HttpClientType.retrofit:
          buffer.writeln('\t// Hint: Use _client.method() for Retrofit');
        case HttpClientType.custom:
          buffer.writeln('\t// Hint: Implement custom HTTP logic here');
      }
    }

    buffer.writeln('\tthrow UnimplementedError();');
  }

  void _generateConfigBasedImports(
    StringBuffer buffer,
    GeneratorConfig config,
  ) {
    final imports = config.remoteDataSourceConfig.requiredImports;

    if (imports.isNotEmpty) {
      for (final import in imports) {
        buffer.writeln("import '$import';");
      }
      buffer.writeln();
    }
  }
}

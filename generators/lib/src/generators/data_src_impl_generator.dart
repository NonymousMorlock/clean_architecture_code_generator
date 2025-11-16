// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/services/functions.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/core/utils/utils.dart';
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

    // Load configuration for imports
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

    // Generate imports based on configuration
    _generateConfigBasedImports(buffer, config);

    Utils.oneMemberAbstractHandler(
      buffer: buffer,
      methodLength: visitor.methods.length,
    );
    buffer.writeln('abstract interface class $dataSrcName {');
    buffer.writeln('const $dataSrcName();');

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

    // Load configuration instead of prompting user
    final remoteConfig = config.remoteDataSourceConfig;

    // Generate constructor based on YAML configuration
    _generateConfigBasedConstructor(buffer, dataSrcName, remoteConfig);

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
        _generateMethodImplementation(buffer, method, remoteConfig);
        buffer.writeln("}");
        buffer.writeln();
      } else {
        buffer.writeln("@override");
        buffer.writeln(
          "$asynchronyType<$returnType> ${method.name}() "
          "$modifier {",
        );
        _generateMethodImplementation(buffer, method, remoteConfig);
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

  void _generateConfigBasedConstructor(
      StringBuffer buffer, String className, RemoteDataSourceConfig config) {
    final dependencies = config.constructorDependencies;

    if (dependencies.isEmpty) {
      buffer.writeln("const ${className}Impl();");
    } else if (dependencies.length == 1) {
      final dependency = dependencies.first;
      final parts = dependency.split(' ');
      final type = parts[0];
      final name = parts[1];
      buffer.writeln("const ${className}Impl(this._$name);");
      buffer.writeln();
      buffer.writeln("final $type _$name;");
    } else {
      // Multiple dependencies
      buffer.writeln("const ${className}Impl({");
      for (final dependency in dependencies) {
        final parts = dependency.split(' ');
        final type = parts[0];
        final name = parts[1];
        buffer.writeln("required $type $name,");
      }
      buffer.writeln("}) : ");

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
        buffer.writeln("final $type _$name;");
      }
    }
    buffer.writeln();
  }

  void _generateMethodImplementation(
      StringBuffer buffer, dynamic method, RemoteDataSourceConfig config) {
    buffer.writeln("\t// TODO(${method.name}): implement ${method.name}");

    // Add configuration-aware implementation hints
    if (config.useFirebaseFirestore &&
        method.name.toLowerCase().contains('get')) {
      buffer.writeln(
          "\t// Hint: Use _firestore.collection('...').get() for Firestore");
    } else if (config.useFirebaseAuth &&
        method.name.toLowerCase().contains('auth')) {
      buffer.writeln(
          "\t// Hint: Use _firebaseAuth.signInWithEmailAndPassword() for auth");
    } else if (config.useGraphQL &&
        (method.name.toLowerCase().contains('get') ||
            method.name.toLowerCase().contains('fetch'))) {
      buffer
          .writeln("\t// Hint: Use _graphQLClient.query() for GraphQL queries");
    } else if (config.useWebSockets &&
        method.name.toLowerCase().contains('stream')) {
      buffer.writeln(
          "\t// Hint: Use _webSocketChannel.stream for WebSocket streams");
    } else if (config.useSupabase) {
      if (method.name.toLowerCase().contains('get')) {
        buffer.writeln(
            "\t// Hint: Use _supabaseClient.from('table').select() for Supabase queries");
      } else if (method.name.toLowerCase().contains('create') ||
          method.name.toLowerCase().contains('insert')) {
        buffer.writeln(
            "\t// Hint: Use _supabaseClient.from('table').insert() for Supabase inserts");
      }
    } else {
      // Default HTTP implementation hint
      switch (config.httpClient) {
        case HttpClientType.dio:
          if (method.name.toLowerCase().contains('get')) {
            buffer.writeln(
                "\t// Hint: Use _dio.get('/endpoint') for GET requests");
          } else if (method.name.toLowerCase().contains('post') ||
              method.name.toLowerCase().contains('create')) {
            buffer.writeln(
                "\t// Hint: Use _dio.post('/endpoint', data: data) for POST requests");
          } else if (method.name.toLowerCase().contains('put') ||
              method.name.toLowerCase().contains('update')) {
            buffer.writeln(
                "\t// Hint: Use _dio.put('/endpoint', data: data) for PUT requests");
          } else if (method.name.toLowerCase().contains('delete')) {
            buffer.writeln(
                "\t// Hint: Use _dio.delete('/endpoint') for DELETE requests");
          }
          break;
        case HttpClientType.http:
          buffer.writeln(
              "\t// Hint: Use _client.get(Uri.parse('url')) for HTTP requests");
          break;
        case HttpClientType.chopper:
          buffer.writeln(
              "\t// Hint: Use _client.getService<ApiService>().method() for Chopper");
          break;
        case HttpClientType.retrofit:
          buffer.writeln("\t// Hint: Use _client.method() for Retrofit");
          break;
        default:
          buffer.writeln(
              "\t// Hint: Implement using configured HTTP client: ${config.httpClient}");
      }
    }

    buffer.writeln("\tthrow UnimplementedError();");
  }

  void _generateConfigBasedImports(
      StringBuffer buffer, GeneratorConfig config) {
    final imports = config.remoteDataSourceConfig.requiredImports;

    if (imports.isNotEmpty) {
      buffer.writeln('// Configuration-based imports');
      for (final import in imports) {
        buffer.writeln("import '$import';");
      }
      buffer.writeln();
    }
  }
}

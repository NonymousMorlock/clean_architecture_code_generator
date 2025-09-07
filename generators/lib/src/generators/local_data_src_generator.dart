// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/services/functions.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/core/utils/utils.dart';
import 'package:generators/src/visitors/usecase_visitor.dart';
import 'package:source_gen/source_gen.dart';

class LocalDataSrcGenerator extends GeneratorForAnnotation<LocalDataSrcGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);
    final buffer = StringBuffer();
    localDataSrc(buffer, visitor);
    localDataSrcImpl(buffer, visitor);
    return buffer.toString();
  }

  void localDataSrc(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    final localDataSrcName = '${className.substring(0, className.length - 4)}LocalDataSrc';
    
    Utils.oneMemberAbstractHandler(
      buffer: buffer,
      methodLength: visitor.methods.length,
    );
    
    buffer.writeln('abstract interface class $localDataSrcName {');
    buffer.writeln('const $localDataSrcName();');
    
    for (final method in visitor.methods) {
      final returnType = method.returnType.modelizeType;
      final isStream = method.returnType.startsWith('Stream');
      final param = method.params == null
          ? ''
          : method.params!.map((e) => paramToString(method, e)).join(', ');
      final asynchronyType = isStream ? 'Stream' : 'Future';
      buffer.writeln('$asynchronyType<$returnType> ${method.name}($param);');
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  void localDataSrcImpl(StringBuffer buffer, RepoVisitor visitor) {
    final className = visitor.className;
    final localDataSrcName = '${className.substring(0, className.length - 4)}LocalDataSrc';
    final implClassName = '${localDataSrcName}Impl';
    
    buffer.writeln('class $implClassName implements $localDataSrcName {');
    buffer.writeln('const $implClassName(this._sharedPreferences);');
    buffer.writeln();
    buffer.writeln('final SharedPreferences _sharedPreferences;');
    buffer.writeln();
    
    for (final method in visitor.methods) {
      final returnType = method.returnType.modelizeType;
      final isStream = method.returnType.startsWith('Stream');
      final asynchronyType = isStream ? 'Stream' : 'Future';
      
      buffer.writeln('@override');
      
      if (method.params != null) {
        final params = method.params!
            .map((param) => paramToString(method, param))
            .join(', ');
        buffer.writeln('$asynchronyType<$returnType> ${method.name}($params) async {');
      } else {
        buffer.writeln('$asynchronyType<$returnType> ${method.name}() async {');
      }
      
      if (isStream) {
        buffer.writeln('// TODO(${method.name}): implement ${method.name} stream from local storage');
        buffer.writeln('throw UnimplementedError();');
      } else {
        if (method.name.toLowerCase().contains('get') || method.name.toLowerCase().contains('fetch')) {
          _generateGetMethod(buffer, method, returnType);
        } else if (method.name.toLowerCase().contains('save') || method.name.toLowerCase().contains('store') || method.name.toLowerCase().contains('cache')) {
          _generateSaveMethod(buffer, method, returnType);
        } else if (method.name.toLowerCase().contains('delete') || method.name.toLowerCase().contains('remove') || method.name.toLowerCase().contains('clear')) {
          _generateDeleteMethod(buffer, method, returnType);
        } else {
          buffer.writeln('// TODO(${method.name}): implement ${method.name}');
          buffer.writeln('throw UnimplementedError();');
        }
      }
      
      buffer.writeln('}');
      buffer.writeln();
    }
    buffer.writeln('}');
  }

  void _generateGetMethod(StringBuffer buffer, dynamic method, String returnType) {
    final methodName = method.name;
    final key = '_${methodName.snakeCase}_key';
    
    buffer.writeln('const $key = \'$methodName\';');
    buffer.writeln('final cachedData = _sharedPreferences.getString($key);');
    buffer.writeln('if (cachedData != null) {');
    
    if (returnType.startsWith('List<')) {
      buffer.writeln('final List<dynamic> jsonList = jsonDecode(cachedData) as List<dynamic>;');
      final modelType = returnType.substring(5, returnType.length - 1);
      buffer.writeln('return jsonList.map((json) => ${modelType}.fromMap(json as DataMap)).toList();');
    } else if (returnType.toLowerCase() == 'string') {
      buffer.writeln('return cachedData;');
    } else if (returnType.toLowerCase() == 'int') {
      buffer.writeln('return int.parse(cachedData);');
    } else if (returnType.toLowerCase() == 'double') {
      buffer.writeln('return double.parse(cachedData);');
    } else if (returnType.toLowerCase() == 'bool') {
      buffer.writeln('return cachedData.toLowerCase() == \'true\';');
    } else {
      buffer.writeln('final json = jsonDecode(cachedData) as DataMap;');
      buffer.writeln('return ${returnType}.fromMap(json);');
    }
    
    buffer.writeln('}');
    buffer.writeln('throw const CacheException(message: \'No cached data found\', statusCode: 404);');
  }

  void _generateSaveMethod(StringBuffer buffer, dynamic method, String returnType) {
    final methodName = method.name;
    final key = '_${methodName.snakeCase}_key';
    final param = method.params?.first;
    
    buffer.writeln('const $key = \'$methodName\';');
    
    if (param != null) {
      final paramName = param.name;
      final paramType = param.type;
      
      if (paramType.startsWith('List<')) {
        buffer.writeln('final jsonList = ${paramName}.map((item) => item.toMap()).toList();');
        buffer.writeln('await _sharedPreferences.setString($key, jsonEncode(jsonList));');
      } else if (paramType.toLowerCase() == 'string') {
        buffer.writeln('await _sharedPreferences.setString($key, $paramName);');
      } else if (paramType.toLowerCase() == 'int') {
        buffer.writeln('await _sharedPreferences.setString($key, ${paramName}.toString());');
      } else if (paramType.toLowerCase() == 'double') {
        buffer.writeln('await _sharedPreferences.setString($key, ${paramName}.toString());');
      } else if (paramType.toLowerCase() == 'bool') {
        buffer.writeln('await _sharedPreferences.setString($key, ${paramName}.toString());');
      } else {
        buffer.writeln('await _sharedPreferences.setString($key, jsonEncode(${paramName}.toMap()));');
      }
    }
    
    if (returnType.toLowerCase() != 'void') {
      buffer.writeln('// Return success indicator or the saved data');
      buffer.writeln('// TODO: Implement appropriate return value');
      buffer.writeln('throw UnimplementedError();');
    }
  }

  void _generateDeleteMethod(StringBuffer buffer, dynamic method, String returnType) {
    final methodName = method.name;
    final key = '_${methodName.snakeCase}_key';
    
    buffer.writeln('const $key = \'$methodName\';');
    buffer.writeln('await _sharedPreferences.remove($key);');
    
    if (returnType.toLowerCase() != 'void') {
      buffer.writeln('// Return success indicator');
      buffer.writeln('// TODO: Implement appropriate return value');
      buffer.writeln('throw UnimplementedError();');
    }
  }
}

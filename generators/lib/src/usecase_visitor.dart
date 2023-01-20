// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:generators/src/function.dart';

class UsecaseVisitor extends SimpleElementVisitor<void> {
  String className = '';
  List<IFunction> methods = [];
  @override
  void visitMethodElement(MethodElement element) {
    final params = element.parameters;
    final methodParams = <Param>[];
    for (var e in params) {
      methodParams.add(Param(name: e.name, type: e.type.toString()));
    }

    final method = IFunction(
        name: element.name,
        returnType: element.returnType.toString().replaceFirst('*', ''),
        params: methodParams.isEmpty ? null : methodParams);
    methods.add(method);
  }

  @override
  void visitConstructorElement(ConstructorElement element) {
    final returnType = element.returnType.toString();
    className = returnType.replaceFirst('*', '').replaceAll('TBG', '');
  }
}

// IFunction(
//         name: removeStaff,
//         returnType: Future<String>,
//         param: [Param(name: name, type: String)]
//       );

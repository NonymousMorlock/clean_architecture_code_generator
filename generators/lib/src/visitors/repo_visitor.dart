import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/models/param.dart';

/// Visitor for extracting repository information from Dart AST elements.
///
/// This visitor traverses the AST of a repository interface annotated
/// with `@repoGen` and extracts information about its methods.
class RepoVisitor extends SimpleElementVisitor2<void> {
  /// The name of the repository class being visited.
  String className = '';

  /// List of methods found in the repository interface.
  List<IFunction> methods = [];

  @override
  void visitMethodElement(MethodElement element) {
    final methodParams = <Param>[];
    final params = element.formalParameters;
    for (final paramElement in params) {
      methodParams.add(
        Param.fromElement(paramElement),
      );
    }

    final method = IFunction(
      name: element.name ?? element.displayName,
      rawType: element.returnType,
      returnType: element.returnType.toString().replaceFirst('*', ''),
      params: methodParams.isEmpty ? null : methodParams,
    );
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

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:generators/src/models/function.dart';

/// Visitor for extracting repository information from Dart AST elements.
///
/// This visitor traverses the AST of a repository interface annotated
/// with `@repoGen` and extracts information about its methods.
class RepoVisitor extends SimpleElementVisitor<void> {
  /// The name of the repository class being visited.
  String className = '';

  /// List of methods found in the repository interface.
  List<IFunction> methods = [];

  @override
  void visitMethodElement(MethodElement element) {
    final params = element.parameters;
    final methodParams = <Param>[];
    for (final e in params) {
      methodParams.add(
        Param(
          name: e.name,
          type: e.type.toString(),
          isNamed: e.isNamed,
          isOptional: e.isOptional,
          isOptionalNamed: e.isOptionalNamed,
          isRequired: e.isRequired,
          isRequiredNamed: e.isRequiredNamed,
          isRequiredPositional: e.isRequiredPositional,
          isPositional: e.isPositional,
          isOptionalPositional: e.isOptionalPositional,
        ),
      );
    }

    final method = IFunction(
      name: element.name,
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

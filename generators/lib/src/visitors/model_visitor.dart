import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:generators/src/models/param.dart';

/// Type alias for a map containing dynamic data.
typedef DataMap = Map<String, dynamic>;

/// Visitor for extracting model information from Dart AST elements.
///
/// This visitor traverses the AST of a class annotated with `@modelGen`
/// and extracts information about its fields and constructor.
class ModelVisitor extends SimpleElementVisitor2<void> {
  /// The name of the class being visited.
  String className = '';

  /// Map of fields found in the class.
  List<Param> params = [];

  @override
  void visitConstructorElement(ConstructorElement element, [void _]) {
    final returnType = element.returnType.getDisplayString();
    className = returnType.replaceFirst('*', '').replaceAll('TBG', '');

    params = element.formalParameters.map(Param.fromElement).toList();
  }
}

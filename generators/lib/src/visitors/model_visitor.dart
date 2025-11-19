import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:generators/core/services/string_extensions.dart';
import 'package:generators/src/models/field.dart';

/// Type alias for a map containing dynamic data.
typedef DataMap = Map<String, dynamic>;

/// Visitor for extracting model information from Dart AST elements.
///
/// This visitor traverses the AST of a class annotated with `@modelGen`
/// and extracts information about its fields and constructor.
class ModelVisitor extends SimpleElementVisitor<void> {
  /// The name of the class being visited.
  String className = '';

  /// Map of field names to their types.
  Map<String, String> fields = {};

  /// Map of field names to their [Field] properties.
  Map<String, Field> fieldProperties = {};

  @override
  void visitConstructorElement(ConstructorElement element) {
    final returnType = element.returnType.toString();
    className = returnType.replaceFirst('*', '').replaceAll('TBG', '');

    for (final param in element.parameters) {
      final typeStr = param.type
          .toString()
          .replaceFirst('*', '')
          .replaceFirst('?', '');

      fields[param.name] = typeStr;
      final isRequired = param.isRequiredNamed || param.isRequiredPositional;

      fieldProperties[param.name.camelCase] = Field.fromMap({
        'name': param.name.camelCase,
        'required': isRequired,
        // For parameters, "initialized" usually implies having a default value
        'initialized': param.hasDefaultValue,
        // Use the parameter's location, or fall back to the library source
        'filePath': '${element.library.source.fullName};'.trim(),
      });
    }
  }
}

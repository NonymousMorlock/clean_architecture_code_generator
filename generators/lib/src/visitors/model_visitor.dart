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
  }

  @override
  void visitFieldElement(FieldElement element) {
    fields[element.name] = element.type.toString().replaceFirst('*', '');
    fieldProperties[element.name.camelCase] = Field.fromMap({
      'name': element.name.camelCase,
      'required': element.hasRequired,
      'initialized': element.hasInitializer,
      'filePath': '${element.location.toString().split(';')[0]};'.trim(),
    });
  }
}

// declaration = bool? is_adult

// children = []

// context = Instance of 'AnalysisContextImpl'

// displayName = is_adult

// docComment = null

// enclosingElement = class PersonTBG

// useResult = false

// kind = FIELD

// library =

// libSource = /example/lib/person.dart

// location = package:example/person.dart;package:example/person.dart;PersonTBG;is_adult

// metdata = [@Required get required]

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';

/// Visitor to identify custom entity candidates from Dart types.
//// It traverses the type structure, filtering out system types
/// and architecture-specific wrappers (like Either and Failure),
/// collecting only relevant custom entity type names.
class EntityCandidateVisitor extends UnifyingTypeVisitor<void> {
  /// Collected entity candidate names.
  final Set<String> candidates = {};

  @override
  void visitDartType(DartType type) {
    // Fallback for types we don't explicitly handle (dynamic, void, Never)
    // We do nothing here, which effectively ignores them.
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    // Check if it is a System/Dart Core type
    // We check the library definition to catch all core types
    // (String, int, List, etc.)
    if (type.element.library.isInSdk) {
      // Even if it's a system container (List, Map), we must check its generics
      // e.g. List<User> -> We need to find User
      for (final arg in type.typeArguments) {
        arg.accept(this);
      }
      return;
    }

    final name = type.element.name;

    // Handle Architecture Specifics (Either)
    // Checks if the name is Either AND it has 2 arguments (Left, Right)
    if (name == 'Either' && type.typeArguments.length >= 2) {
      // Logic: Ignore Left (Failure), Visit Right (Success)
      type.typeArguments[1].accept(this);
      return;
    }

    // Handle Architecture Specifics (Failure)
    // Skip any class that has 'Failure' in the name
    if (name != null && name.contains('Failure')) {
      return;
    }

    if (name == 'Option' && type.typeArguments.isNotEmpty) {
      type.typeArguments.first.accept(this);
      return;
    }

    // Handle enums
    if (type.element is EnumElement) return;

    // It is a Custom Entity
    candidates.add(type.displayString(withNullability: false));

    // Recurse (e.g. PaginatedList<User>)
    // The Custom Type itself might have generics that are ALSO entities
    for (final arg in type.typeArguments) {
      arg.accept(this);
    }
  }
}

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';

/// {@template right_type_visitor}
/// A visitor that peels off "Wrapper" layers (Future, Stream, Either)
/// to reveal the underlying success type.
/// {@endtemplate}
class SuccessTypeVisitor extends UnifyingTypeVisitor<DartType> {
  /// {@macro right_type_visitor}
  const SuccessTypeVisitor();

  @override
  DartType visitDartType(DartType type) {
    // Default: If we don't know how to unwrap it, return the type itself.
    return type;
  }

  @override
  DartType visitInterfaceType(InterfaceType type) {
    // 1. Unwrap Future / Stream
    if (type.isDartAsyncFuture || type.isDartAsyncStream) {
      if (type.typeArguments.isNotEmpty) {
        // Recurse into the inner type (e.g. Future<Either<...>>)
        return type.typeArguments.first.accept(this);
      }
    }

    // 2. Unwrap Either (Architecture specific)
    // Check name and ensure it has 2 args
    if (type.element.name == 'Either' && type.typeArguments.length >= 2) {
      // Recurse into the "Right" side (Success)
      return type.typeArguments[1].accept(this);
    }

    // 3. Unwrap Option (Architecture specific)
    if (type.element.name == 'Option' && type.typeArguments.isNotEmpty) {
      return type.typeArguments.first.accept(this);
    }

    // If it's a List<User>, we stop here. List is data, not a wrapper.
    return type;
  }
}

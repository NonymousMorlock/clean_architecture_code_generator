import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/src/visitors/entity_candidate_visitor.dart';
import 'package:generators/src/visitors/success_type_visitor.dart';

/// Extension methods for DartType manipulation in code generation.
extension DartTypeExtensions on DartType {
  /// Recursively unwraps Future, Stream, and Either to find the "Success" type.
  DartType get successType => accept(const SuccessTypeVisitor());

  /// Converts the DartType to a model class name string.
  String get modelize {
    // 1. Primitives: return as-is
    if (!hasCustomType) return toString();

    final type = this;

    // 2. Generics (Recursion)
    if (type is InterfaceType && type.typeArguments.isNotEmpty) {
      final name = element?.name ?? '';
      final args = type.typeArguments.map((t) => t.modelize).join(', ');
      return '$name<$args>';
    }

    // 3. Custom Types
    // Check if it's strictly a custom class
    final name = element?.name ?? '';
    // Apply your naming logic
    if (!name.endsWith('Model')) {
      return '${name}Model';
    }

    return name;
  }

  /// Checks if the type ITSELF is a custom user-defined type,
  /// without considering type arguments.
  ///
  /// For deeper custom type check, use [hasCustomType].
  bool get surfaceIsCustomType {
    if (this is VoidType || this is DynamicType || this is NeverType) {
      return false;
    }

    // This catches String, int, bool, List, Map, Set,
    // Uri, BigInt, DateTime, etc.
    if (element?.library?.isInSdk ?? false) {
      return false;
    }

    // Filter Architecture Wrappers (Failure, Either, etc.)
    // These are libraries, but not "Models" we want to generate.
    final name = element?.name ?? '';
    if (name == 'Either' || name == 'Option' || name.contains('Failure')) {
      return false;
    }

    return true;
  }

  /// RECURSIVE CHECK
  /// Uses the EntityCandidateVisitor.
  /// If the visitor finds ANY candidates, then `hasCustomType` is true.
  bool get hasCustomType {
    return entityCandidates.isNotEmpty;
  }

  /// Gathers all custom type candidates from the type
  /// and its type arguments.
  Set<String> get entityCandidates {
    final visitor = EntityCandidateVisitor();
    accept(visitor);
    return visitor.candidates;
  }

  /// Recursively digs into the rightmost type argument.
  ///
  /// Example:
  /// - `Stream<Either<Failure, List<User>>>` -> `User`
  /// - `Future<String>` -> `String`
  /// - `Map<String, int>` -> `int`
  DartType get deepestType {
    final current = this;

    // We can only dig into InterfaceTypes (classes/mixins with type arguments)
    if (current is InterfaceType && current.typeArguments.isNotEmpty) {
      // .last ensures we favor the Right side of Either<L, R>
      // or the Value of Map<K, V>
      final rightmostArgument = current.typeArguments.last;

      // If the rightmost argument is also an InterfaceType, keep digging
      return rightmostArgument.deepestType;
    }

    return current;
  }

  /// Checks if the type is nullable.
  bool get isNullable {
    return nullabilitySuffix == NullabilitySuffix.question ||
        this is DynamicType;
  }

  /// Checks if the type is a Dart core constant type.
  bool get isConst {
    return isDartCoreInt ||
        isDartCoreDouble ||
        isDartCoreNull ||
        isDartCoreNum ||
        isDartCoreBool ||
        isDartCoreString ||
        isDartCoreSymbol ||
        isDartCoreList ||
        isDartCoreSet ||
        isDartCoreMap;
  }

  /// Gets a display string without legacy Dart 2.x syntax.
  String displayString({bool withNullability = true}) {
    // getDisplayString(withNullability: true)
    // ensures we get 'User?' or 'User' correctly.
    return withNullability
        ? getDisplayString()
        : getDisplayString().replaceAll('?', '');
  }

  /// Checks if the type is DateTime.
  bool get isDateTime {
    if (element == null) return false;
    return element!.name == 'DateTime' &&
        // This ensures we don't accidentally pick up a 'DateTime' class
        // from a 3rd party package.
        (element!.library?.isDartCore ?? false);
  }

  /// Checks if the type is an enum.
  bool get isEnum {
    return element is EnumElement;
  }

  /// Returns a fallback value based on the type.
  ///
  /// Used in `.empty` constructor generation to provide appropriate default
  /// values.
  ///
  /// DO NOT USE IN CASES WITH LOOSE TYPE CONSTRAINTS.
  Expression fallbackValue({
    bool useConstForCollections = true,
    bool skipIfNullable = true,
    bool useModelForCustomType = false,
  }) {
    if (isNullable && skipIfNullable) return literalNull;

    final targetRawType = this;

    // Helper: Extracts the type argument as a Reference
    // (e.g., List<String> -> refer('String'))
    Reference? getTypeArg({
      required int index,
      bool useModelForCustomType = false,
    }) {
      if (targetRawType is InterfaceType &&
          targetRawType.typeArguments.length > index) {
        final arg = targetRawType.typeArguments[index];
        if (useModelForCustomType && arg.hasCustomType) {
          return refer(arg.modelize);
        }
        return refer(arg.displayString());
      }
      return null;
    }

    if (targetRawType.isDartCoreSet) {
      if (useConstForCollections) return literalConstSet({});
      // Generates: <Type>{}
      return literalSet(
        {},
        getTypeArg(index: 0, useModelForCustomType: useModelForCustomType),
      );
    }

    if (targetRawType.isDartCoreList || targetRawType.isDartCoreIterable) {
      if (useConstForCollections) return literalConstList([]);
      // Generates: <Type>[]
      return literalList(
        [],
        getTypeArg(index: 0, useModelForCustomType: useModelForCustomType),
      );
    }

    if (targetRawType.isDartCoreMap) {
      if (useConstForCollections) return literalConstMap({});
      // Generates: <Key, Value>{}
      return literalMap(
        {},
        getTypeArg(index: 0, useModelForCustomType: useModelForCustomType),
        getTypeArg(index: 1, useModelForCustomType: useModelForCustomType),
      );
    }
    if (targetRawType.isDartCoreString) {
      return literalString('Test String');
    }
    if (targetRawType.isDartCoreDouble) {
      return literalNum(1.0);
    }
    if (targetRawType.isDartCoreNum || targetRawType.isDartCoreInt) {
      return literalNum(1);
    }
    if (targetRawType.isDartCoreBool) {
      return literalTrue;
    }
    if (targetRawType.isDateTime) {
      return const Reference('DateTime').newInstanceNamed('now', []);
    }
    if (targetRawType.isDartCoreRecord) {
      return literalConstRecord([], {});
    }
    if (targetRawType.isEnum) {
      return refer(
        targetRawType.displayString(withNullability: false),
      ).property('values').property('first');
    }
    if (targetRawType.hasCustomType) {
      final modelClassName = useModelForCustomType
          ? modelize
          : displayString(withNullability: false);
      return Reference(modelClassName).newInstanceNamed('empty', []);
    }
    if (targetRawType.isDartCoreType) {
      return Reference(displayString(withNullability: false)).newInstance([]);
    }

    return literalNull;
  }
}

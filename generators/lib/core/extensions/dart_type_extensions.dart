import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/extensions/string_extensions.dart';

/// Extension methods for DartType manipulation in code generation.
extension DartTypeExtensions on DartType {
  /// Recursively unwraps Future, Stream, and Either to find the "Success" type.
  DartType get rightType {
    var current = this;

    while (true) {
      // 1. Unwrap Future/Stream
      if (current.isDartAsyncFuture || current.isDartAsyncStream) {
        if (current is InterfaceType && current.typeArguments.isNotEmpty) {
          current = current.typeArguments.first;
          continue;
        }
      }

      // 2. Unwrap Either (Check explicit name because
      // Either isn't in dart:core)
      // We check the Element's name, which is safer
      // than the string representation
      if (current.element?.name == 'Either' && current is InterfaceType) {
        if (current.typeArguments.length >= 2) {
          current = current.typeArguments[1]; // The 'Right' side
          continue;
        }
      }

      // 3. Unwrap Dartz-style Option (if you use it)
      if (current.element?.name == 'Option' && current is InterfaceType) {
        if (current.typeArguments.isNotEmpty) {
          current = current.typeArguments.first;
          continue;
        }
      }

      break;
    }
    return current;
  }

  /// Converts the DartType to a model class name string.
  String get modelize {
    // 1. Primitives: return as-is
    if (!isCustomType) return toString();

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

  /// Unwraps Future or Stream once to get the inner type.
  DartType get innerType {
    var current = this;

    // Unwrap Future/Stream once
    if (current.isDartAsyncFuture || current.isDartAsyncStream) {
      if (current is InterfaceType && current.typeArguments.isNotEmpty) {
        current = current.typeArguments.first;
      }
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
    // then we sanitize legacy Dart 2.x syntax ('*') if present
    return getDisplayString(
      withNullability: withNullability,
    ).replaceAll('*', '');
  }

  /// Checks if the type is DateTime.
  bool get isDateTime {
    if (element == null) return false;
    return element!.name == 'DateTime' &&
        // This ensures we don't accidentally pick up a 'DateTime' class
        // from a 3rd party package.
        (element!.library?.isDartCore ?? false);
  }

  /// Checks if the type is a custom user-defined type.
  bool get isCustomType {
    return displayString(withNullability: false).isCustomType;
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
    Reference? getTypeArg(int index) {
      if (targetRawType is InterfaceType &&
          targetRawType.typeArguments.length > index) {
        final arg = targetRawType.typeArguments[index];
        return refer(arg.displayString());
      }
      return null;
    }

    if (targetRawType.isDartCoreSet) {
      if (useConstForCollections) return literalConstSet({});
      // Generates: <Type>{}
      return literalSet({}, getTypeArg(0));
    }

    if (targetRawType.isDartCoreList || targetRawType.isDartCoreIterable) {
      if (useConstForCollections) return literalConstList([]);
      // Generates: <Type>[]
      return literalList([], getTypeArg(0));
    }

    if (targetRawType.isDartCoreMap) {
      if (useConstForCollections) return literalConstMap({});
      // Generates: <Key, Value>{}
      return literalMap({}, getTypeArg(0), getTypeArg(1));
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
    if (targetRawType.isCustomType) {
      final modelClassName = useModelForCustomType
          ? '${displayString(withNullability: false)}Model'
          : displayString(withNullability: false);
      return Reference(modelClassName).newInstanceNamed('empty', []);
    }
    if (targetRawType.isDartCoreType) {
      return Reference(displayString(withNullability: false)).newInstance([]);
    }

    return literalNull;
  }
}

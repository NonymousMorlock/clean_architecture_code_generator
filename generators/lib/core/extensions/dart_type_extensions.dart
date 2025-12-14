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
  String get displayString {
    // getDisplayString(withNullability: true)
    // ensures we get 'User?' or 'User' correctly.
    // then we sanitize legacy Dart 2.x syntax ('*') if present
    return getDisplayString(withNullability: true).replaceAll('*', '');
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
    final targetType = targetRawType.rightType.displayString;
    final base = targetType.baseType.toLowerCase().replaceAll('?', '');

    // Helper: Extracts the type argument as a Reference
    // (e.g., List<String> -> refer('String'))
    Reference? getTypeArg(int index) {
      if (targetRawType is InterfaceType &&
          targetRawType.typeArguments.length > index) {
        final arg = targetRawType.typeArguments[index];
        return refer(arg.displayString);
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
    if (base.contains('datetime')) {
      return const Reference('DateTime').newInstanceNamed('now', []);
    }
    if (targetRawType.isDartCoreRecord) {
      return literalConstRecord([], {});
    }
    if (base.isCustomType) {
      final modelClassName = useModelForCustomType
          ? '${targetType.replaceAll('?', '')}Model'
          : targetType.replaceAll('?', '');
      return Reference(modelClassName).newInstanceNamed('empty', []);
    }
    if (targetRawType.isDartCoreType) {
      return Reference(targetType.replaceAll('?', '')).newInstance([]);
    }

    return literalNull;
  }
}

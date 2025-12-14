import 'package:code_builder/code_builder.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/src/models/param.dart';

/// Extension methods for DartType manipulation in code generation.
extension ParamExtensions on Param {
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
    return rawType.fallbackValue(
      useConstForCollections: useConstForCollections,
      skipIfNullable: skipIfNullable,
      useModelForCustomType: useModelForCustomType,
    );
  }
}

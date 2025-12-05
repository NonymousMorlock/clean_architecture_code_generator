import 'package:code_builder/code_builder.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/src/models/function.dart';

/// Extension methods for method builder manipulation in code generation.
extension MethodBuilderExtensions on MethodBuilder {
  /// Automatically populates required and optional parameters based on
  /// the [IFunction] definition.
  ///
  /// [useModels]: If true, converts custom types to their model counterparts
  /// (e.g., `User` -> `UserModel`). Useful for Remote Data Sources.
  void addParamsFrom(IFunction method, {bool useModels = false}) {
    Reference resolve(String type) {
      return Reference(useModels ? type.modelizeType : type);
    }

    // -----------------------------------------------------------
    // BUCKET 1: The "Naked" Zone (Strictly Positional)
    // -----------------------------------------------------------
    requiredParameters.addAll(
      method.params?.where((p) => p.isRequiredPositional).map(
            (param) {
              return Parameter(
                (b) => b
                  ..name = param.name
                  ..type = resolve(param.type),
                // .named defaults to false
              );
            },
          ) ??
          [],
    );
    // -----------------------------------------------------------
    // BUCKET 2: The "Bracket" Zone (Named OR Optional Positional)
    // -----------------------------------------------------------
    optionalParameters.addAll(
      // We look for anything Named (required or not) OR Optional Positional
      method.params
              ?.where(
                (p) => p.isNamed || p.isOptionalPositional,
              )
              .map(
                (param) {
                  return Parameter(
                    (b) {
                      b
                        ..name = param.name
                        ..type = resolve(param.type)
                        ..named = param.isNamed;

                      // This is the magic flag that turns 'optionalParameters'
                      // into 'required named parameters'
                      if (param.isRequiredNamed) {
                        b.required = true;
                      }
                    },
                  );
                },
              ) ??
          [],
    );
  }
}

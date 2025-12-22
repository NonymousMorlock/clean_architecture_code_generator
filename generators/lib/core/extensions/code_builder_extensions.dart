import 'package:code_builder/code_builder.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
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
    if (method.params == null) return;

    Reference resolve(String type) {
      return Reference(useModels ? type.modelizeType : type);
    }

    for (final param in method.params!) {
      // Create the parameter definition once
      final parameter = Parameter((paramBuilder) {
        paramBuilder
          ..name = param.name
          ..type = resolve(param.rawType.displayString())
          // Defaults to false, correct for positional
          ..named = param.isNamed;

        // "required" keyword logic:
        // Only applies to named parameters in Dart ({required String x})
        if (param.isRequiredNamed) {
          paramBuilder.required = true;
        }
      });

      // DISTRIBUTION LOGIC
      // -----------------------------------------------------------
      // BUCKET 1: The "Naked" Zone (Strictly Positional)
      // -----------------------------------------------------------
      if (param.isRequiredPositional) {
        requiredParameters.add(parameter);
      }
      // -----------------------------------------------------------
      // BUCKET 2: The "Bracket" Zone (Named OR Optional Positional)
      // -----------------------------------------------------------
      else {
        optionalParameters.add(parameter);
      }
    }
  }
}

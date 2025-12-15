import 'package:code_builder/code_builder.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/models/param.dart';

/// Extension methods for IFunction manipulation in code generation.
extension IFunctionExtensions on IFunction {
  /// Extracts both positional and named arguments in a single pass.
  ///
  /// [transformer]: Optional function to transform parameter values.
  /// - If it returns a [String], it will be wrapped in `refer()`.
  /// - If it returns an [Expression], it will be used directly.
  ///
  /// Returns a record with `positional` list and `named` map.
  ({List<Expression> positional, Map<String, Expression> named}) extractArgs({
    Object Function(Param)? transformer,
  }) {
    final positional = <Expression>[];
    final named = <String, Expression>{};

    final parameters = params;
    if (parameters == null || parameters.isEmpty) {
      return (positional: positional, named: named);
    }

    for (final param in parameters) {
      Expression value;

      // 1. Determine the value (Transformed or Default)
      if (transformer != null) {
        final result = transformer(param);

        if (result is String) {
          // Wrap string results: "tName" -> refer("tName")
          value = refer(result);
        } else if (result is Expression) {
          // Pass expressions through: literal(1) -> literal(1)
          value = result;
        } else {
          throw ArgumentError(
            'Transformer must return a String or Expression, '
            'but returned ${result.runtimeType} for param ${param.name}',
          );
        }
      } else {
        // Default: just refer to the parameter name
        value = refer(param.name);
      }

      // 2. Sort into the correct bucket
      if (param.isNamed) {
        named[param.name] = value;
      } else {
        positional.add(value);
      }
    }

    return (positional: positional, named: named);
  }
}

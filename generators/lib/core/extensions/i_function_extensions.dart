import 'package:code_builder/code_builder.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/models/param.dart';

/// Extension methods for IFunction manipulation in code generation.
extension IFunctionExtensions on IFunction {
  /// Extracts parameters that should be passed positionally.
  /// Returns: [param1, param2]
  List<Expression> get positionalValues {
    return params
            ?.where((param) => !param.isNamed)
            .map((param) => refer(param.name))
            .toList() ??
        [];
  }

  /// Extracts positional parameters and applies a transformation.
  ///
  /// [transformer] - A function to transform each parameter's name.
  /// Returns a list of transformed expressions for positional parameters.
  List<Expression> positionalValuesWithTransform(
    String Function(Param) transformer,
  ) {
    return params
            ?.where((param) => !param.isNamed)
            .map((param) => refer(transformer(param)))
            .toList() ??
        [];
  }

  /// Extracts parameters that should be passed by name.
  /// Returns: { 'id': id, 'name': name }
  Map<String, Expression> get namedValues {
    return {
      for (final param in params?.where((param) => param.isNamed) ?? <Param>[])
        param.name: refer(param.name),
    };
  }

  /// Extracts named parameters and applies a transformation to their values.
  ///
  /// [transformer] - A function to transform each parameter's name.
  /// Returns a map of parameter names to transformed expressions.
  Map<String, Expression> namedValuesWithTransform(
    String Function(Param) transformer,
  ) {
    return {
      for (final param in params?.where((param) => param.isNamed) ?? <Param>[])
        param.name: refer(transformer(param)),
    };
  }
}

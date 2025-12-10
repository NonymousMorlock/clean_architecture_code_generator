import 'package:analyzer/dart/element/type.dart';
import 'package:generators/src/models/param.dart';

/// Represents a function/method in generated code.
///
/// Contains information about the function's name, return type,
/// and parameters.
class IFunction {
  /// Creates an [IFunction] with the given properties.
  ///
  /// The [shouldHaveCustomParams] is automatically set to true if
  /// [params] has more than one parameter.
  const IFunction({
    required this.name,
    required this.rawType,
    required this.returnType,
    this.params,
  }) : shouldHaveCustomParams = params != null && params.length > 1;

  /// The name of the function.
  final String name;

  /// Whether this function should have custom parameter handling.
  ///
  /// Set to true when the function has more than one parameter.
  final bool shouldHaveCustomParams;

  /// The list of parameters for this function.
  final List<Param>? params;

  /// The return type of the function.
  final String returnType;

  /// The raw return type of the function
  final DartType rawType;

  /// Returns true if this function has parameters.
  bool get hasParams => params?.isNotEmpty ?? false;

  @override
  String toString() =>
      '''
      IFunction(
        name: $name,
        returnType: $returnType,
        param: $params
      );
      ''';
}

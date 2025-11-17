import 'package:equatable/equatable.dart';

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

/// Represents a parameter in a function/method.
///
/// Contains detailed information about the parameter's type, name,
/// and various characteristics (named, optional, required, etc.).
class Param extends Equatable {
  /// Creates a [Param] with the given properties.
  const Param({
    required this.isNamed,
    required this.isOptional,
    required this.isOptionalNamed,
    required this.isRequired,
    required this.isRequiredNamed,
    required this.isRequiredPositional,
    required this.isPositional,
    required this.isOptionalPositional,
    required this.name,
    required this.type,
  });

  /// Creates an empty [Param] with all boolean flags set to false.
  const Param.empty()
    : this(
        isNamed: false,
        isOptional: false,
        isOptionalNamed: false,
        isRequired: false,
        isRequiredNamed: false,
        isRequiredPositional: false,
        isPositional: false,
        isOptionalPositional: false,
        name: '',
        type: '',
      );

  /// The name of the parameter.
  final String name;

  /// The type of the parameter.
  final String type;

  /// Whether this is a named parameter.
  final bool isNamed;

  /// Whether this is an optional parameter.
  final bool isOptional;

  /// Whether this is an optional named parameter.
  final bool isOptionalNamed;

  /// Whether this is a required parameter.
  final bool isRequired;

  /// Whether this is a required named parameter.
  final bool isRequiredNamed;

  /// Whether this is a required positional parameter.
  final bool isRequiredPositional;

  /// Whether this is a positional parameter.
  final bool isPositional;

  /// Whether this is an optional positional parameter.
  final bool isOptionalPositional;

  /// Returns the parameter as a formatted string for code generation.
  ///
  /// Includes the 'required' keyword if this is a required named parameter.
  String get param => '${isRequiredNamed ? 'required ' : ''}$type $name';

  @override
  String toString() => 'Param(name: $name, type: $type)';

  @override
  List<Object?> get props => [name, type];
}

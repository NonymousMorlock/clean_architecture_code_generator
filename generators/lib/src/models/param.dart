import 'package:analyzer/dart/element/type.dart';
import 'package:equatable/equatable.dart';

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
    required this.rawType,
    required this.isNullable,
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
        isNullable: false,
        rawType: null,
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

  /// Whether this is a nullable parameter
  final bool isNullable;

  /// The raw type of the parameter.
  final DartType? rawType;

  /// Returns the parameter as a formatted string for code generation.
  ///
  /// Includes the 'required' keyword if this is a required named parameter.
  String get param => '${isRequiredNamed ? 'required ' : ''}$type $name';

  @override
  String toString() => 'Param(name: $name, type: $type)';

  @override
  List<Object?> get props => [name, type];
}

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:equatable/equatable.dart';
import 'package:generators/src/models/empty_type.dart';

/// Represents a parameter in a function/method.
///
/// Contains detailed information about the parameter's type, name,
/// and various characteristics (named, optional, required, etc.).
class Param extends Equatable {
  /// Creates a [Param] with the given properties.
  const Param({
    required this.isNamed,
    required this.isRequired,
    required this.name,
    required this.rawType,
    required this.isNullable,
    required this.type,
    required this.hasDefaultValue,
    this.defaultValueCode,
  });

  /// Creates an empty [Param] with all boolean flags set to false.
  const Param.empty()
    : this(
        isNamed: false,
        isRequired: false,
        isNullable: false,
        rawType: const EmptyType(),
        hasDefaultValue: false,
        name: '',
        type: '',
      );

  /// Factory to create a Param from the Analyzer's ParameterElement.
  /// This centralizes all the parsing logic from your visitors.
  factory Param.fromElement(ParameterElement element) {
    final isNullable =
        element.type.nullabilitySuffix == NullabilitySuffix.question;

    final isDynamic = element.type is DynamicType;

    return Param(
      name: element.name,
      type: element.type.toString().replaceFirst('*', '').replaceAll('?', ''),
      rawType: element.type,
      isNullable: isNullable || isDynamic,
      isNamed: element.isNamed,
      // Logic: It is required if it's strictly required (positional or named)
      isRequired: element.isRequired,
      hasDefaultValue: element.hasDefaultValue,
      defaultValueCode: element.defaultValueCode,
    );
  }

  /// The name of the parameter.
  final String name;

  /// The type of the parameter.
  final String type;

  /// Whether this is a named parameter.
  final bool isNamed;

  /// Whether this is a required parameter.
  final bool isRequired;

  /// Whether this is a nullable parameter
  final bool isNullable;

  /// The raw type of the parameter.
  final DartType rawType;

  /// Whether this parameter has a default value
  final bool hasDefaultValue;

  /// The default value code for this parameter.
  ///
  /// This is only available if [hasDefaultValue] is true.
  ///
  /// e.g: `'10'` for `int` or `'true'` for `bool`
  final String? defaultValueCode;

  /// Is this parameter positional? (The opposite of named)
  bool get isPositional => !isNamed;

  /// Is this parameter optional? (The opposite of required)
  bool get isOptional => !isRequired;

  /// Is this a Named parameter that is Required? ({required String x})
  bool get isRequiredNamed => isNamed && isRequired;

  /// Is this a Named parameter that is Optional? ({String? x})
  bool get isOptionalNamed => isNamed && !isRequired;

  /// Is this a Positional parameter that is Required? (String x)
  bool get isRequiredPositional => !isNamed && isRequired;

  /// Is this a Positional parameter that is Optional? ([String? x])
  bool get isOptionalPositional => !isNamed && !isRequired;

  /// Returns the parameter as a formatted string for code generation.
  ///
  /// Includes the 'required' keyword if this is a required named parameter.
  String get param => '${isRequiredNamed ? 'required ' : ''}$type $name';

  @override
  String toString() => 'Param(name: $name, type: $type)';

  @override
  List<Object?> get props => [
    name,
    type,
    isNullable,
    isRequired,
    hasDefaultValue,
    defaultValueCode,
    isRequired,
    isOptional,
  ];
}

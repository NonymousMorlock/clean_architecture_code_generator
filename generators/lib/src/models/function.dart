import 'package:equatable/equatable.dart';

class IFunction {
  const IFunction({
    required this.name,
    this.params,
    required this.returnType,
  }) : shouldHaveCustomParams = params != null && params.length > 1;

  final String name;
  final bool shouldHaveCustomParams;
  final List<Param>? params;
  final String returnType;

  @override
  String toString() => '''IFunction(
        name: $name,
        returnType: $returnType,
        param: $params
      );''';
}

class Param extends Equatable{
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

  final String name;
  final String type;
  final bool isNamed;
  final bool isOptional;
  final bool isOptionalNamed;
  final bool isRequired;
  final bool isRequiredNamed;
  final bool isRequiredPositional;
  final bool isPositional;
  final bool isOptionalPositional;

  String get param => '${isRequiredNamed ? 'required ' : ''}$type $name';

  @override
  String toString() => 'Param(name: $name, type: $type)';

  @override
  // TODO: implement props
  List<Object?> get props => [name, type];
}

class IFunction {
  const IFunction({required this.name, this.params, required this.returnType});
  final String name;
  final List<Param>? params;
  final String returnType;

  @override
  String toString() => '''IFunction(
        name: $name,
        returnType: $returnType,
        param: $params
      );''';
}

class Param {
  const Param({required this.name, required this.type});

  final String name;
  final String type;
  String get param => 'required $type $name';

  @override
  String toString() => 'Param(name: $name, type: $type)';
}

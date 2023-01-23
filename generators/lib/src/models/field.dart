import 'package:generators/src/visitors/model_visitor.dart';

class Field {
  const Field._({
    required this.name,
    required this.isInitialized,
    required this.isRequired,
    required this.filePath,
  });

  factory Field.fromMap(DataMap map) => Field._(
      name: map['name'],
      isInitialized: map['initialized'],
      isRequired: map['required'],
      filePath: map['filePath']);

  final String name;
  final bool isInitialized;
  final bool isRequired;
  final String filePath;

  @override
  String toString() => '''Field(
        name: $name,
        isRequired: $isRequired,
        isInitialized: $isInitialized,
        filePath: '$filePath',
      );''';
}

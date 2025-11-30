import 'package:generators/src/visitors/model_visitor.dart';

/// Represents a field in a generated class.
///
/// Contains information about the field's name, initialization state,
/// requirement status, and source file path.
class Field {
  /// Creates a [Field] with the given properties.
  const Field({
    required this.name,
    required this.isInitialized,
    required this.isRequired,
    required this.filePath,
  });

  /// Creates a [Field] from a map of properties.
  ///
  /// The map should contain:
  /// - `name`: The field name (String)
  /// - `initialized`: Whether the field is initialized (bool)
  /// - `required`: Whether the field is required (bool)
  /// - `filePath`: The source file path (String)
  factory Field.fromMap(DataMap map) => Field(
    name: map['name'] as String,
    isInitialized: map['initialized'] as bool,
    isRequired: map['required'] as bool,
    filePath: map['filePath'] as String,
  );

  /// The name of the field.
  final String name;

  /// Whether the field is initialized with a default value.
  final bool isInitialized;

  /// Whether the field is required (non-nullable).
  final bool isRequired;

  /// The file path where this field is defined.
  final String filePath;

  @override
  String toString() =>
      '''
      Field(
        name: $name,
        isRequired: $isRequired,
        isInitialized: $isInitialized,
        filePath: '$filePath',
      );
      ''';
}

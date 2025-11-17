import 'package:generators/src/models/field.dart';
import 'package:test/test.dart';

void main() {
  group('Field', () {
    test('can be instantiated from map', () {
      final map = {
        'name': 'testField',
        'initialized': true,
        'required': false,
        'filePath': '/path/to/file.dart',
      };

      final field = Field.fromMap(map);

      expect(field.name, equals('testField'));
      expect(field.isInitialized, isTrue);
      expect(field.isRequired, isFalse);
      expect(field.filePath, equals('/path/to/file.dart'));
    });

    test('toString returns formatted string', () {
      final map = {
        'name': 'id',
        'initialized': false,
        'required': true,
        'filePath': '/lib/models/user.dart',
      };

      final field = Field.fromMap(map);
      final stringValue = field.toString();

      expect(stringValue, contains('Field('));
      expect(stringValue, contains('name: id'));
      expect(stringValue, contains('isRequired: true'));
      expect(stringValue, contains('isInitialized: false'));
      expect(stringValue, contains("filePath: '/lib/models/user.dart'"));
    });
  });
}

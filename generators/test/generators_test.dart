import 'package:flutter_test/flutter_test.dart';
import 'package:generators/core/services/string_extensions.dart';

void main() {
  test('adds one to input values', () {
    const name = 'staff';
    final result = convertName(name);
    expect(result, 'staff');
  });
}

String convertName(String name) {
  final split = name.split('_');
  var converted = split[0];
  for (var i = 1; i < split.length; i++) {
    converted += split[i].titleCase;
  }
  return converted;
}

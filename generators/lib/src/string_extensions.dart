extension StringExt on String {
  String capitalize() {
    if (trim().isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String get titleCase {
    if (trim().isEmpty) return this;
    return split(' ').map<String>((e) => e.capitalize()).toList().join(' ');
  }

  String get camelCase {
    final splitString = split('_');
    var converted = splitString[0];
    for (var i = 1; i < splitString.length; i++) {
      converted += splitString[i].titleCase;
    }
    return converted;
  }

  String get upperCamelCase {
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get rightType {
    return replaceAll('Future', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('Either', '')
        .replaceAll('Failure', '')
        .replaceAll(',', '')
        .trim();
  }
}

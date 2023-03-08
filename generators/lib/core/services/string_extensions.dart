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

  String get lowerCamelCase {
    return '${this[0].toLowerCase()}${substring(1)}';
  }

  String get rightType {
    final result = replaceAll('Future', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('Either', '')
        .replaceAll('Failure', '')
        .replaceAll(',', '')
        .trim();
    if (result.toLowerCase().startsWith('list')) {
      return '${result.substring(0, 4)}<${result.substring(4)}>';
    }
    return result;
  }

  dynamic get fallbackValue {
    if (toLowerCase().startsWith('list')) {
      return [];
    } else if (rightType.toLowerCase().startsWith('list')) {
      return [];
    } else if (toLowerCase().startsWith('string')) {
      return 'Test String';
    } else if (toLowerCase().startsWith('int') ||
        toLowerCase().startsWith('double')) {
      return 1;
    } else if (toLowerCase().startsWith('bool')) {
      return true;
    } else if (toLowerCase().startsWith('datetime')) {
      return 'DateTime.now()';
    } else if (toLowerCase().startsWith('map')) {
      return {};
    } else if (rightType.trim().startsWith('void')) {
      return 'null';
    } else {
      return '$this.empty()';
    }
  }

  dynamic get copyWithFallback {
    if (toLowerCase().startsWith('string')) {
      return "''";
    } else if (toLowerCase().startsWith('int')) {
      return 0;
    } else if (toLowerCase().startsWith('double')) {
      return 0.0;
    } else if (toLowerCase().startsWith('datetime')) {
      return 'DateTime.now().add(const Duration(days: 1))';
    } else if (toLowerCase().startsWith('bool')) {
      return false;
    }
  }
}

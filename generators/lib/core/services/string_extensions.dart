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

  String get snakeCase {
    return replaceAllMapped(
      RegExp('([A-Z])'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceAll(RegExp('^_'), '');
  }

  String get upperCamelCase {
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get lowerCamelCase {
    return '${this[0].toLowerCase()}${substring(1)}';
  }

  String get stripType {
    if (contains('<')) {
      // final type = substring(0, indexOf('<'));
      final type2 = substring(indexOf('<') + 1, lastIndexOf('>'));
      if (type2.contains('<')) {
        return type2;
      }
      return type2;
    }
    return this;
  }

  String get rightType {
    final result = replaceAll('Future', '')
        .replaceAll('Stream', '')
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

  String get modelizeType {
    var returnType = rightType;
    final tempReturnType =
        returnType.split('<').last.replaceAll('<', '').replaceAll('>', '');
    final returnTypeFallback = tempReturnType.fallbackValue;
    if (returnTypeFallback is String && returnTypeFallback.isCustomType) {
      returnType =
          returnType.replaceAll(tempReturnType, '${tempReturnType}Model');
    }
    return returnType;
  }

  /// Stream<Either<Failure, List<Object>>> will return
  /// Either<Failure, List<Object>>
  String get innerType {
    final splitData = split('<').sublist(1).join('<');
    final length = splitData.length;
    return splitData.split('').sublist(0, length - 1).join();
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

  bool get isCustomType {
    return contains('.empty()');
  }
}

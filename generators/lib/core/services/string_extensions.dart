/// Extension methods for String manipulation in code generation.
extension StringExt on String {
  /// Capitalizes the first letter of the string.
  String capitalize() {
    if (trim().isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Converts the string to title case (each word capitalized).
  String get titleCase {
    if (trim().isEmpty) return this;
    return split(' ').map<String>((e) => e.capitalize()).toList().join(' ');
  }

  /// Converts snake_case string to camelCase.
  String get camelCase {
    final splitString = split('_');
    final buffer = StringBuffer(splitString[0]);
    for (var i = 1; i < splitString.length; i++) {
      buffer.write(splitString[i].titleCase);
    }
    return buffer.toString();
  }

  /// Converts camelCase or PascalCase string to snake_case.
  String get snakeCase {
    return replaceAllMapped(
      RegExp('([A-Z])'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceAll(RegExp('^_'), '');
  }

  /// Converts the first character to uppercase (PascalCase).
  String get upperCamelCase {
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts the first character to lowercase (camelCase).
  String get lowerCamelCase {
    return '${this[0].toLowerCase()}${substring(1)}';
  }

  /// Strips the outer type wrapper and returns the inner generic type.
  ///
  /// Example: `Future<String>` returns `String`
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

  /// Extracts the core type from a complex type signature.
  ///
  /// Removes `Future`, `Stream`, `Either`, `Failure` wrappers and returns
  /// the actual data type.
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

  /// Converts entity types to model types by appending 'Model'.
  ///
  /// Example: `User` becomes `UserModel`
  String get modelizeType {
    var returnType = rightType;
    final tempReturnType = returnType
        .split('<')
        .last
        .replaceAll('<', '')
        .replaceAll('>', '');
    final returnTypeFallback = tempReturnType.fallbackValue;
    if (returnTypeFallback is String && returnTypeFallback.isCustomType) {
      returnType = returnType.replaceAll(
        tempReturnType,
        '${tempReturnType}Model',
      );
    }
    return returnType;
  }

  /// `Stream<Either<Failure, List<Object>>>` will return
  /// `Either<Failure, List<Object>>`
  String get innerType {
    final splitData = split('<').sublist(1).join('<');
    final length = splitData.length;
    return splitData.split('').sublist(0, length - 1).join();
  }

  /// Returns a fallback value for testing based on the type.
  ///
  /// Used in test generation to provide appropriate default values.
  dynamic get fallbackValue {
    if (toLowerCase().startsWith('list')) {
      return <dynamic>[];
    } else if (rightType.toLowerCase().startsWith('list')) {
      return <dynamic>[];
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
      return <dynamic, dynamic>{};
    } else if (rightType.trim().startsWith('void')) {
      return 'null';
    } else {
      return '$this.empty()';
    }
  }

  /// Returns a different value for copyWith tests.
  ///
  /// Used to test that copyWith methods properly update values.
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

  /// Checks if this is a custom type (not a built-in Dart type).
  bool get isCustomType {
    return contains('.empty()');
  }
}

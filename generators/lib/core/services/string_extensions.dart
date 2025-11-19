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

  /// Helper: Finds the content inside the *first* pair of outer brackets.
  /// Returns null if no brackets exist.
  String? get _rawContentInsideBrackets {
    final start = indexOf('<');
    final end = lastIndexOf('>');
    if (start == -1 || end == -1 || end < start) return null;
    return substring(start + 1, end);
  }

  /// Helper: Splits a string by comma, but ignores commas inside
  /// nested brackets.
  ///
  /// Input: `"String, Map<int, String>"` -> `["String", "Map<int, String>"]`
  List<String> _splitGenericParams(String input) {
    final result = <String>[];
    var depth = 0;
    var startIndex = 0;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '<') {
        depth++;
      } else if (char == '>') {
        depth--;
      } else if (char == ',' && depth == 0) {
        // We found a comma at the root level
        result.add(input.substring(startIndex, i).trim());
        startIndex = i + 1; // Skip the comma
      }
    }

    // Add the last segment
    if (startIndex < input.length) {
      result.add(input.substring(startIndex).trim());
    }

    return result;
  }

  /// Extracts the inner type argument.
  ///
  /// * `List` -> Returns `null` (Or empty string if you prefer, but
  /// null is safer)
  /// * `List<String>` -> Returns `String`
  /// * `Map<String, int>` -> Returns `String, int`
  /// * `Stream<Either<Failure, List<Object>>>` ->
  /// `Either<Failure, List<Object>>`
  String? get innerType {
    return _rawContentInsideBrackets;
  }

  /// Recursively unwraps `Future`, `Stream`, and extracts the Right
  /// side of `Either`.
  ///
  /// * `List<String>` -> `List<String>`
  /// * `Future<List<String>>` -> `List<String>`
  /// * `Stream<Either<Failure, List<Object>>>` -> `List<Object>`
  String get rightType {
    var current = trim();

    // 1. Recursive Unwrap: Remove Future<...> and Stream<...> layers
    while (current.startsWith('Future<') || current.startsWith('Stream<')) {
      final inner = current._rawContentInsideBrackets;
      if (inner == null) break;
      current = inner.trim();
    }

    // 2. Handle Either: specifically looks for Either<L, R> pattern
    if (current.startsWith('Either<')) {
      final content = current._rawContentInsideBrackets;
      if (content != null) {
        final params = _splitGenericParams(content);
        // Either should have 2 params. We want the Right (2nd) one.
        if (params.length >= 2) {
          return params[1].trim(); // Return the Right side
        }
      }
    }

    // 3. Return the remaining type (e.g., List<String>, User, int)
    return current;
  }

  /// Determines if the type or its deeply nested children are custom types.
  ///
  /// Uses a recursive check on the "base" type structure.
  bool get isCustomType {
    // 1. Clean the type (remove formatting, ? nullable indicators)
    final typeToCheck = trim().replaceAll('?', '');

    // 2. Base Primitive Check (Fast fail)
    // If the whole string is a primitive, we are done.
    const primitives = {
      'int',
      'double',
      'num',
      'bool',
      'string',
      'void',
      'dynamic',
      'object',
      'datetime',
    };
    if (primitives.contains(typeToCheck.toLowerCase())) return false;

    // 3. If it's a generic container (List, Map, Future, Stream),
    // check INNER types.
    // We check if it starts with standard containers.
    if (typeToCheck.contains('<')) {
      final baseContainer = typeToCheck
          .substring(0, typeToCheck.indexOf('<'))
          .trim();
      final innerContent = typeToCheck._rawContentInsideBrackets;

      const standardContainers = {
        'list',
        'map',
        'set',
        'future',
        'stream',
        'either',
      };

      if (standardContainers.contains(baseContainer.toLowerCase())) {
        // It is a standard container, so we must check the children.
        if (innerContent == null) return false;

        final children = _splitGenericParams(innerContent);
        // Recursion: If ANY child is custom, the whole
        // thing implies custom handling
        return children.any((child) => child.isCustomType);
      }

      // If the container itself is not standard
      // (e.g. PaginatedList<User>), it is custom.
      return true;
    }

    // 4. If we are here, it's a single word (e.g. "User", "ArtworkTBG")
    // that isn't a primitive.
    return true;
  }
}

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
  /// Handles nested generics: `List<User>` -> `List<UserModel>`
  String get modelizeType {
    final current = trim();

    // 1. If it's a container, recurse into arguments
    if (current.contains('<')) {
      final base = baseType;
      final args = typeArguments;
      final modelizedArgs = args.map((e) => e.modelizeType).join(', ');
      return '$base<$modelizedArgs>';
    }

    // 2. If it is a primitive, leave it alone
    if (!isCustomType) {
      return current;
    }

    // 3. It is a custom type (e.g. "User" or "UserTBG"), append Model
    // Remove '?' temporarily
    final cleanName = current.replaceAll('?', '');
    final isNullable = current.endsWith('?');

    // Logic to avoid double naming if it already ends in Model (optional)
    if (cleanName.endsWith('Model')) return current;

    return '${cleanName}Model${isNullable ? '?' : ''}';
  }

  /// Returns a fallback value for testing based on the type.
  ///
  /// Used in test generation to provide appropriate default values.
  dynamic get fallbackValue {
    // 1. Analyze the "Right Type" (ignoring Futures/Streams for the value)
    final targetType = rightType;
    final base = targetType.baseType.toLowerCase().replaceAll('?', '');

    if (base == 'list' || base == 'iterable' || base == 'set') {
      return '[]'; // Works for List<User> too
    }
    if (base == 'map') {
      return '{}';
    }
    if (base == 'string') {
      return '"Test String"'; // standardized with quotes
    }
    if (base == 'int' || base == 'num') {
      return '1';
    }
    if (base == 'double') {
      return '1.0';
    }
    if (base == 'bool') {
      return 'true';
    }
    if (base == 'datetime') {
      return 'DateTime.now()';
    }
    if (base == 'void') {
      return 'null';
    }

    // Fallback for Custom Types: Use `.empty()` constructor
    // We strip the '?' in case it's nullable, because usually we want
    // the concrete empty object for tests/defaults.
    return '${targetType.replaceAll('?', '')}.empty()';
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

  /// Returns the outer container name.
  /// `Map<String, int>` -> `Map`
  /// `List<String>` -> `List`
  /// `String` -> `String`
  String get baseType {
    final index = indexOf('<');
    if (index == -1) return trim();
    return substring(0, index).trim();
  }

  /// Returns a list of the immediate generic arguments.
  ///
  /// * `List<String>` -> `['String']`
  /// * `Map<String, List<int>>` -> `['String', 'List<int>']`
  /// * `String` -> `[]`
  List<String> get typeArguments {
    final content = _rawContentInsideBrackets;
    if (content == null) return [];
    return _splitGenericParams(content);
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

    // Unwrap Wrappers
    while (true) {
      if (current.startsWith('Future<') || current.startsWith('Stream<')) {
        current = current._rawContentInsideBrackets?.trim() ?? current;
      } else if (current.startsWith('Either<')) {
        final args = current.typeArguments;
        if (args.length >= 2) {
          current = args[1]; // Take the Right side
        } else {
          break; // Malformed Either
        }
      } else {
        break; // No more wrappers
      }
    }

    return current;
  }

  /// Determines if the type or its deeply nested children are custom types.
  ///
  /// Uses a recursive check on the "base" type structure.
  bool get isCustomType {
    final core = rightType; // Inspect the core type
    final base = core.baseType.toLowerCase().replaceAll('?', '');

    const systemTypes = {
      'int',
      'double',
      'num',
      'bool',
      'string',
      'void',
      'dynamic',
      'object',
      'datetime',
      'list',
      'map',
      'set',
      'iterable',
    };

    if (systemTypes.contains(base)) {
      // It's a system container, but check the children!
      // e.g. List<User> -> List is system, but User is custom.
      final args = core.typeArguments;
      if (args.isEmpty) return false;

      // If ANY argument is custom, the whole thing is custom
      return args.any((arg) => arg.isCustomType);
    }

    return true;
  }

  /// Recursively extracts all leaf types from a complex generic signature.
  ///
  /// Input: `Future<Either<Failure, Map<Category, List<Product>>>>`
  /// Output:
  /// `{'Future', 'Either', 'Failure', 'Map', 'Category', 'List', 'Product'}`
  Set<String> get allConstituentTypes {
    final types = <String>{};
    final current = trim();

    // If it has generics, split and recurse
    if (current.contains('<')) {
      // Add the container itself (e.g., "Map")
      types.add(current.baseType);

      // Recurse into arguments
      for (final arg in current.typeArguments) {
        types.addAll(arg.allConstituentTypes);
      }
    } else {
      // It's a leaf type
      types.add(current.replaceAll('?', ''));
    }

    return types;
  }

  /// Checks if a type is likely a clean architecture Entity.
  /// Filters out primitives, collections, and core types like Failure/Either.
  bool get isPotentialEntity {
    final lower = toLowerCase();
    const ignored = {
      // Primitives
      'int',
      'double',
      'num',
      'bool',
      'string',
      'void',
      'dynamic',
      'object',
      'datetime',
      // Collections
      'list',
      'map',
      'set',
      'iterable',
      'future',
      'stream',
      // Core Architecture
      'either',
      'failure',
      'serverfailure',
      'cachefailure',
      'nointernetfailure',
    };

    return !ignored.contains(lower);
  }

  /// Recursively digs for the "Success" entity type based on
  /// Clean Arch patterns.
  ///
  /// Rules:
  /// 1. Wrappers (Future, Stream, List, Set) -> Dig into the inner type.
  /// 2. Biased Types (Either) -> Dig into the RIGHT type (Success).
  /// 3. Map -> Dig into the RIGHT type (Value).
  /// 4. Leaf -> If it's not a primitive, it's a candidate.
  Set<String> get entityCandidates {
    final candidates = <String>{};
    final cleanType = trim().replaceAll('?', ''); // Remove nullability

    // 1. Base case: No generics? Check if it's a custom type.
    if (!cleanType.contains('<')) {
      if (_isCustomType(cleanType)) {
        candidates.add(cleanType);
      }
      return candidates;
    }

    // 2. Analyze Container
    final base = cleanType.baseType; // "Future", "Either", "Map"
    final args = cleanType.typeArguments; // ["Failure", "User"]

    if (args.isEmpty) return candidates;

    // 3. Apply Structural Rules
    switch (base.toLowerCase()) {
      // --- ONE-HAND WRAPPERS ---
      case 'future':
      case 'stream':
      case 'list':
      case 'set':
      case 'iterable':
        // Just dig deeper into the single argument
        // e.g., List<User> -> User
        candidates.addAll(args.first.entityCandidates);

      // --- TWO-HAND BIASED (Clean Arch / Dartz) ---
      case 'either':
        // The 'Left' is Failure. We ONLY care about the 'Right' (Index 1).
        if (args.length >= 2) {
          candidates.addAll(args[1].entityCandidates);
        }

      // --- KEY-VALUE ---
      case 'map':
        // Usually Map<Id, Entity>. We prioritize the Value (Index 1).
        // If you have Map<Entity, int>, this might miss,
        // but that's rare in Repos.
        if (args.length >= 2) {
          candidates.addAll(args[1].entityCandidates);
        }

      // --- UNKNOWN GENERICS (e.g. PaginatedResponse<User>) ---
      default:
        // Safest bet: Check ALL arguments.
        for (final arg in args) {
          candidates.addAll(arg.entityCandidates);
        }
    }

    return candidates;
  }

  /// Helper to filter out primitives
  bool _isCustomType(String type) {
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
      'null',
    };
    return !primitives.contains(type.toLowerCase());
  }
}

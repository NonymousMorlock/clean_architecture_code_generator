import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/english_morphology.dart';

/// Utility class to generate standardized state class names
/// based on usecase method names and feature context.
class StateNameGenerator {
  // Clean Architecture Intent Clusters
  // We map specific technical synonyms to standardized architecture states.
  static const Map<String, String> _intentMap = {
    // READ
    'get': 'Loaded',
    'fetch': 'Loaded',
    'load': 'Loaded',
    'read': 'Loaded',
    'retrieve': 'Loaded',
    'search': 'Loaded',
    'filter': 'Loaded',

    // CREATE
    'create': 'Created',
    'add': 'Created', // or 'Added'
    'insert': 'Created',
    'post': 'Created',

    // UPDATE
    'update': 'Updated',
    'modify': 'Updated',
    'edit': 'Updated',
    'patch': 'Updated',
    'change': 'Updated',

    // DELETE
    'delete': 'Deleted',
    'remove': 'Deleted', // or 'Removed'
    'erase': 'Deleted',
    'clear': 'Deleted',

    // AUTH/ACCESS (Intransitive usually)
    'login': 'LoggedIn',
    'logout': 'LoggedOut',
    'signin': 'SignedIn',
    'signIn': 'SignedIn',
    'signup': 'SignedUp',
    'signUp': 'SignedUp',
    'register': 'Registered',
  };

  /// Generates the success state class name.
  ///
  /// [methodName]: The usecase method (e.g., 'getFeaturedProducts')
  ///
  /// [featureName]: The feature context (e.g., 'Product')
  ///
  /// [returnType]: Optional, used for pluralization hints
  /// (e.g., `List<Product>`)
  static String generate({
    required String methodName,
    required String featureName,
    String? returnType,
  }) {
    // 1. Tokenize (CamelCase Split)
    // e.g., 'getFeaturedProducts' -> ['get', 'Featured', 'Products']
    final tokens = _splitCamelCase(methodName);
    // Ultimate fallback
    if (tokens.isEmpty) return '${featureName}Success';

    final verb = tokens.first.toLowerCase();

    // 2. Determine State Suffix (The "Action")
    String stateSuffix;

    if (_intentMap.containsKey(verb)) {
      // Use standardized Architecture term
      stateSuffix = _intentMap[verb]!;
    } else {
      // Use Morphology Engine for custom verbs
      // (verify -> Verified, ban -> Banned)
      final pastTense = EnglishMorphology.convertToPastParticiple(verb);
      stateSuffix = pastTense.capitalize();
    }

    // 3. Determine Subject (The "Target")
    String subject;

    if (tokens.length > 1) {
      // The subject is explicitly in the method name
      // ['get', 'Featured', 'Products'] -> 'FeaturedProducts'
      subject = tokens.sublist(1).map((e) => e.capitalize()).join();
    } else {
      // No subject in method name (e.g., 'login', 'submit', 'save')

      // Edge Case: If the mapped state is already a
      // full standalone concept (LoggedIn), use it.
      if (_intentMap.containsKey(verb) &&
          stateSuffix.startsWith(verb.capitalize().substring(0, 2))) {
        // e.g. login -> LoggedIn. We don't want "AuthLoggedIn".
        // Just "LoggedIn".
        // But "get" -> "Loaded". We DO want "AuthLoaded".
        // Heuristic: If the stateSuffix root is different from the
        // verb root, it needs a subject.
        return stateSuffix;
      }

      // Fallback: Use the Feature Name
      subject = featureName;
    }

    // 4. Pluralization & List Handling (Refining the Subject)
    // If the subject is just the FeatureName (e.g. 'User') but
    // return type is List, make it 'Users'
    if (returnType != null && returnType.toLowerCase().startsWith('list')) {
      if (!subject.endsWith('s')) {
        // Simple pluralization.
        // We could use a morphology engine for plurals too,
        // but 's' covers 95% of generic models.
        subject = '${subject}s';
      }
    }

    // 5. Assembly
    return '$subject$stateSuffix';
  }

  /// Helper: Splits camelCase string into list of words.
  /// getFeaturedProducts -> [get, Featured, Products]
  static List<String> _splitCamelCase(String input) {
    if (input.isEmpty) return [];
    // Regex splits before capital letters
    final beforeCapitalLetter = RegExp('(?=[A-Z])');
    return input.split(beforeCapitalLetter).where((s) => s.isNotEmpty).toList();
  }
}

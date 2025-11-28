import 'package:generators/generators.dart';

/// Utility class for code generation helpers.
sealed class Utils {
  /// Private constructor to prevent instantiation.
  const Utils();

  /// Adds a lint ignore comment for single-method abstract classes.
  ///
  /// When an interface has only one method, adds an ignore comment
  /// to suppress the `one_member_abstracts` lint warning.
  static void oneMemberAbstractHandler({
    required StringBuffer buffer,
    required int methodLength,
  }) {
    if (methodLength < 2) {
      buffer.writeAll(
        [
          '// I need this class to be an interface.',
          '// ignore_for_file: one_member_abstracts',
          '',
        ],
        '\n',
      );
    }
  }

  /// Discovers entity candidates used in a repository method.
  ///
  /// Scans the return type and parameters of the method to identify
  /// potential entity dependencies.
  //// Returns a set of entity names as strings.
  static Set<String> discoverMethodEntities(IFunction method) {
    final candidates = <String>{}
      // 1. Scan Return Type (e.g. Future<Either<Failure, List<User>>>)
      // This will automatically strip Future, discard Failure,
      // strip List, and find "User"
      ..addAll(method.returnType.entityCandidates);

    // 2. Scan Parameters (e.g. method(User params))
    if (method.params != null) {
      for (final param in method.params!) {
        candidates.addAll(param.type.entityCandidates);
      }
    }
    return candidates;
  }
}

import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/src/visitors/repo_visitor.dart';

/// Extensions for RepoVisitor
extension RepoVisitorExtensions on RepoVisitor {
  /// Scans all methods to find strict Entity dependencies
  Set<String> discoverRequiredEntities() {
    final candidates = <String>{};

    for (final method in methods) {
      // 1. Scan Return Type (e.g. Future<Either<Failure, List<User>>>)
      // This will automatically strip Future, discard Failure,
      // strip List, and find "User"
      candidates.addAll(method.returnType.entityCandidates);

      // 2. Scan Parameters (e.g. method(User params))
      if (method.params != null) {
        for (final param in method.params!) {
          candidates.addAll(param.type.entityCandidates);
        }
      }
    }
    return candidates;
  }
}

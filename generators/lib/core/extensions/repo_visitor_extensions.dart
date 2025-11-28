import 'package:generators/core/utils/utils.dart';
import 'package:generators/src/visitors/repo_visitor.dart';

/// Extensions for RepoVisitor
extension RepoVisitorExtensions on RepoVisitor {
  /// Scans all methods to find strict Entity dependencies
  Set<String> discoverRequiredEntities() {
    final candidates = <String>{};

    for (final method in methods) {
      candidates.addAll(Utils.discoverMethodEntities(method));
    }

    return candidates;
  }
}

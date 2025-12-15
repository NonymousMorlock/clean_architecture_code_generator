import 'package:generators/generators.dart';

/// Extensions for ModelVisitor
extension ModelVisitorExtensions on ModelVisitor {
  /// Scans all fields to find strict Entity dependencies
  Set<String> discoverRequiredEntities() {
    final candidates = <String>{};

    for (final param in params) {
      // Assuming entity types start with an uppercase letter
      candidates.addAll(param.type.entityCandidates);
    }

    return candidates;
  }
}

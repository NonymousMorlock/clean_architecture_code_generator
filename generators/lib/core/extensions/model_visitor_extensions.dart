import 'package:generators/generators.dart';

/// Extensions for ModelVisitor
extension ModelVisitorExtensions on ModelVisitor {
  /// Scans all fields to find strict Entity dependencies
  Set<String> discoverRequiredEntities() {
    final candidates = <String>{};

    for (final fieldType in fields.values) {
      // Assuming entity types start with an uppercase letter
      candidates.addAll(fieldType.entityCandidates);
    }

    return candidates;
  }
}

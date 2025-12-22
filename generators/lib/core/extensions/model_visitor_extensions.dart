import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/generators.dart';

/// Extensions for ModelVisitor
extension ModelVisitorExtensions on ModelVisitor {
  /// Scans all fields to find strict Entity dependencies
  Set<String> discoverRequiredEntities() {
    final candidates = <String>{};

    for (final param in params) {
      // Assuming entity types start with an uppercase letter
      candidates.addAll(param.rawType.entityCandidates);
    }

    return candidates;
  }
}

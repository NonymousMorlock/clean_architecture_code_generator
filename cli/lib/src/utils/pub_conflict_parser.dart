/// Utility for parsing Flutter pub dependency conflict errors
library;

/// {@template conflict_result}
/// Represents the result of parsing a pub dependency conflict error.
/// {@endtemplate}
class ConflictResult {
  /// {@macro conflict_result}
  const ConflictResult({
    required this.isConflict,
    required this.conflicts,
    required this.rootCause,
    this.suggestedOverrides = const {},
    this.rawError = '',
  });

  /// Whether this is a version conflict error
  final bool isConflict;

  /// List of all conflicting packages identified
  final List<PackageConflict> conflicts;

  /// The root cause package that triggered the conflict
  final String? rootCause;

  /// Suggested dependency_overrides map (package: version)
  final Map<String, String> suggestedOverrides;

  /// Original error message
  final String rawError;

  /// Whether this conflict can be auto-resolved
  bool get canAutoResolve => suggestedOverrides.isNotEmpty;
}

/// {@template package_conflict}
/// Represents a single package involved in a conflict.
/// {@endtemplate}
class PackageConflict {
  /// {@macro package_conflict}
  const PackageConflict({
    required this.packageName,
    required this.conflictingVersions,
    required this.requiredBy,
    this.sourceType = PackageSourceType.pub,
  });

  /// The name of the conflicting package
  final String packageName;

  /// List of version constraints for this package
  final List<VersionConstraint> conflictingVersions;

  /// List of packages that require this package
  final List<String> requiredBy;

  /// The source type of this package
  final PackageSourceType sourceType;
}

/// {@template version_constraint}
/// Version constraint extracted from error message.
/// {@endtemplate}
class VersionConstraint {
  /// {@macro version_constraint}
  const VersionConstraint({
    required this.constraint,
    required this.source,
  });

  /// The version constraint (e.g., ">=6.0.0 <9.0.0", "^9.0.0")
  final String constraint;

  /// Where this constraint comes from
  final String source;
}

/// Package source type
enum PackageSourceType {
  /// Package from pub.dev
  pub,

  /// Package from git repository
  git,

  /// Package from local path
  path,

  /// Package from SDK
  sdk,
}

/// Regex patterns for parsing pub conflict errors
class _PubConflictPatterns {
  /// Detect if this is a version conflict
  static final isVersionConflict = RegExp(
    'version solving failed|is incompatible with|'
    'requires|depends on.*which depends on',
    caseSensitive: false,
  );

  /// Extract git dependency
  static final gitDependency = RegExp(
    r'(\w+(?:_\w+)*)\s+from\s+git',
  );

  /// Extract dependency relationship
  static final dependsOn = RegExp(
    r'(\w+(?:_\w+)*)\s+([^\s]+(?:\s+[<>]=?[\d.]+)?)\s+depends on\s+'
    r'(\w+(?:_\w+)*)\s+([^\s,]+(?:\s+[<>]=?[\d.]+)?)',
  );

  /// Extract "every version of X" pattern
  static final everyVersionOf = RegExp(
    r'every version of\s+(\w+(?:_\w+)*)\s+from\s+(\w+)',
  );

  /// Extract "requires" relationship
  static final requires = RegExp(
    r'(\w+(?:_\w+)*)\s+([^\s]+(?:\s+[<>]=?[\d.]+)?)\s+requires\s+'
    r'(\w+(?:_\w+)*)\s+([^\s,]+(?:\s+or\s+[^\s,]+)?)',
  );

  /// Extract final conclusion
  static final conclusion = RegExp(
    r'So, because\s+(.+?),\s+version solving failed',
    dotAll: true,
  );
}

/// Parser for Flutter pub dependency conflict errors
class PubConflictParser {
  /// Parse stderr output from flutter pub get
  static ConflictResult parse(String stderr) {
    // Phase 1: Quick validation
    if (!_PubConflictPatterns.isVersionConflict.hasMatch(stderr)) {
      return ConflictResult(
        isConflict: false,
        conflicts: const [],
        rootCause: null,
        rawError: stderr,
      );
    }

    // Phase 2: Split into sentences
    final sentences = _tokenizeSentences(stderr);

    // Phase 3: Build conflict map
    final conflictMap = <String, PackageConflict>{};
    final dependencyGraph = <String, List<String>>{};

    for (final sentence in sentences) {
      _extractDependencies(sentence, conflictMap, dependencyGraph);
    }

    // Phase 4: Identify root cause
    final rootCause = _identifyRootCause(stderr, sentences, dependencyGraph);

    // Phase 5: Generate override suggestions
    final overrides = _generateOverrides(conflictMap, rootCause, stderr);

    return ConflictResult(
      isConflict: true,
      conflicts: conflictMap.values.toList(),
      rootCause: rootCause,
      suggestedOverrides: overrides,
      rawError: stderr,
    );
  }

  /// Split error into logical sentences
  static List<String> _tokenizeSentences(String stderr) {
    final lines = stderr.split('\n').where((l) => l.trim().isNotEmpty);
    final sentences = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      // Check if this line starts a new logical sentence
      if (trimmed.startsWith('Because') ||
          trimmed.startsWith('And because') ||
          trimmed.startsWith('So, because')) {
        sentences.add(trimmed);
      } else if (sentences.isNotEmpty) {
        // Continuation of previous sentence
        sentences[sentences.length - 1] += ' $trimmed';
      }
    }

    return sentences;
  }

  /// Extract package dependencies from a sentence
  static void _extractDependencies(
    String sentence,
    Map<String, PackageConflict> conflictMap,
    Map<String, List<String>> dependencyGraph,
  ) {
    // Extract "depends on" patterns
    final dependsMatches = _PubConflictPatterns.dependsOn.allMatches(sentence);
    for (final match in dependsMatches) {
      final dependentPkg = match.group(1)!;
      final dependentVersion = match.group(2)!;
      final requiredPkg = match.group(3)!;
      final requiredVersion = match.group(4)!;

      // Add to dependency graph
      dependencyGraph.putIfAbsent(dependentPkg, () => []).add(requiredPkg);

      // Add to conflict map
      _addToConflictMap(
        conflictMap,
        requiredPkg,
        requiredVersion,
        '$dependentPkg $dependentVersion',
      );
    }

    // Extract "requires" patterns
    final requiresMatches = _PubConflictPatterns.requires.allMatches(sentence);
    for (final match in requiresMatches) {
      final dependentPkg = match.group(1)!;
      final dependentVersion = match.group(2)!;
      final requiredPkg = match.group(3)!;
      final requiredVersion = match.group(4)!;

      _addToConflictMap(
        conflictMap,
        requiredPkg,
        requiredVersion,
        '$dependentPkg $dependentVersion',
      );
    }

    // Extract git dependencies
    final gitMatches = _PubConflictPatterns.gitDependency.allMatches(sentence);
    for (final match in gitMatches) {
      final packageName = match.group(1)!;

      // Look for version requirement for this git package
      // Account for "every version of" prefix
      final pattern =
          r'(?:every version of\s+)?'
          '${RegExp.escape(packageName)}'
          r'\s+from\s+git\s+depends\s+on\s+'
          r'(\w+(?:_\w+)*)\s+([^\s,]+)';
      final versionMatch = RegExp(pattern).firstMatch(sentence);

      if (versionMatch != null) {
        final requiredPkg = versionMatch.group(1)!;
        final requiredVersion = versionMatch.group(2)!;

        _addToConflictMap(
          conflictMap,
          requiredPkg,
          requiredVersion,
          '$packageName from git',
        );
      }

      // Update source type for this package
      if (!conflictMap.containsKey(packageName)) {
        conflictMap[packageName] = PackageConflict(
          packageName: packageName,
          conflictingVersions: const [],
          requiredBy: const [],
          sourceType: PackageSourceType.git,
        );
      }
    }
  }

  /// Add package constraint to conflict map
  static void _addToConflictMap(
    Map<String, PackageConflict> map,
    String packageName,
    String versionConstraint,
    String requiredBy,
  ) {
    if (!map.containsKey(packageName)) {
      map[packageName] = PackageConflict(
        packageName: packageName,
        conflictingVersions: const [],
        requiredBy: const [],
      );
    }

    final existing = map[packageName]!;
    map[packageName] = PackageConflict(
      packageName: existing.packageName,
      conflictingVersions: [
        ...existing.conflictingVersions,
        VersionConstraint(
          constraint: versionConstraint,
          source: requiredBy,
        ),
      ],
      requiredBy: [
        ...existing.requiredBy,
        requiredBy,
      ],
      sourceType: existing.sourceType,
    );
  }

  /// Identify the root cause package (usually a git dependency)
  static String? _identifyRootCause(
    String stderr,
    List<String> sentences,
    Map<String, List<String>> graph,
  ) {
    // Strategy 1: Look for "every version of X from git"
    final everyVersionMatch = _PubConflictPatterns.everyVersionOf.firstMatch(
      stderr,
    );
    if (everyVersionMatch != null && everyVersionMatch.group(2) == 'git') {
      return everyVersionMatch.group(1);
    }

    // Strategy 2: Look for git packages in conclusion
    final conclusionMatch = _PubConflictPatterns.conclusion.firstMatch(stderr);
    if (conclusionMatch != null) {
      final conclusion = conclusionMatch.group(1)!;
      final gitMatch = _PubConflictPatterns.gitDependency.firstMatch(
        conclusion,
      );
      if (gitMatch != null) {
        return gitMatch.group(1);
      }
    }

    // Strategy 3: Find any git dependency mentioned
    final gitMatch = _PubConflictPatterns.gitDependency.firstMatch(stderr);
    if (gitMatch != null) {
      return gitMatch.group(1);
    }

    return null;
  }

  /// Generate dependency override suggestions
  static Map<String, String> _generateOverrides(
    Map<String, PackageConflict> conflicts,
    String? rootCause,
    String stderr,
  ) {
    final overrides = <String, String>{};

    // Packages that shouldn't be overridden (SDK-pinned or circular deps)
    const excludedPackages = {
      'test_api', // Pinned by flutter_test
      'matcher', // Pinned by flutter_test
      'test', // Usually causes more conflicts
      'bloc_test', // User dependency, not a transitive one
    };

    // If we have a clear root cause, find what it DIRECTLY needs
    if (rootCause != null) {
      // Look for direct dependencies in sentences like:
      // "every version of [rootCause] from git depends on [package] [version]"
      final directDepPattern = RegExp(
        'every version of\\s+$rootCause\\s+from\\s+git\\s+depends\\s+on\\s+'
        r'(\w+(?:_\w+)*)\s+([^\s,]+)',
      );

      for (final match in directDepPattern.allMatches(stderr)) {
        final packageName = match.group(1)!;
        final versionConstraint = match.group(2)!;

        // Skip excluded packages
        if (excludedPackages.contains(packageName)) continue;

        // Extract and add the override
        final version = _extractMostSpecificVersion(versionConstraint);
        if (version != null) {
          overrides[packageName] = version;
        }
      }
    }

    return overrides;
  }

  /// Extract the most specific version from a constraint
  /// Priority: exact > caret > range
  static String? _extractMostSpecificVersion(String constraint) {
    // Exact version: "1.2.3"
    final exactMatch = RegExp(r'^(\d+\.\d+\.\d+)$').firstMatch(constraint);
    if (exactMatch != null) {
      return exactMatch.group(1);
    }

    // Caret: "^1.2.3"
    final caretMatch = RegExp(r'\^([\d.]+)').firstMatch(constraint);
    if (caretMatch != null) {
      return '^${caretMatch.group(1)}';
    }

    // Range: ">=1.0.0 <2.0.0" - use lower bound with caret
    final rangeMatch = RegExp(r'>=(\d+\.\d+\.\d+)').firstMatch(constraint);
    if (rangeMatch != null) {
      return '^${rangeMatch.group(1)}';
    }

    return null;
  }
}

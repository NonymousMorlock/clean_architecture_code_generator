import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// {@template pubspec_editor}
/// Utility for safely editing pubspec.yaml files, particularly for
/// adding or updating dependency_overrides.
/// {@endtemplate}
class PubspecEditor {
  /// {@macro pubspec_editor}
  const PubspecEditor();

  /// Add or update dependency overrides in pubspec.yaml
  ///
  /// This method:
  /// - Reads the existing pubspec.yaml file
  /// - Merges new overrides with existing ones (replaces duplicates)
  /// - Sorts all overrides alphabetically
  /// - Preserves formatting, comments, and whitespace using yaml_edit
  ///
  /// Throws [FileSystemException] if the file doesn't exist or can't be read.
  /// Throws [FormatException] if the YAML is invalid.
  static Future<void> addDependencyOverrides({
    required String pubspecPath,
    required Map<String, String> overrides,
  }) async {
    if (overrides.isEmpty) return;

    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      throw FileSystemException('pubspec.yaml not found', pubspecPath);
    }

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    // Get existing dependency_overrides (if any)
    final doc = loadYaml(content) as Map?;
    final existingOverrides = doc?['dependency_overrides'] as Map? ?? {};

    // Merge: new overrides REPLACE existing ones (no duplicates)
    final mergedOverrides = <String, String>{
      ...existingOverrides.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      ...overrides,
    };

    // Sort alphabetically (user requirement)
    final sortedOverrides = Map.fromEntries(
      mergedOverrides.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Update the dependency_overrides section
    // yaml_edit will create the section if it doesn't exist
    editor.update(['dependency_overrides'], sortedOverrides);

    // Write back to file
    await pubspecFile.writeAsString(editor.toString());
  }

  /// Remove dependency overrides from pubspec.yaml
  ///
  /// Removes the specified packages from dependency_overrides.
  /// If the list is empty, removes the entire dependency_overrides section.
  static Future<void> removeDependencyOverrides({
    required String pubspecPath,
    List<String> packages = const [],
  }) async {
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      throw FileSystemException('pubspec.yaml not found', pubspecPath);
    }

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    if (packages.isEmpty) {
      // Remove entire dependency_overrides section
      editor.remove(['dependency_overrides']);
    } else {
      // Remove specific packages
      for (final package in packages) {
        editor.remove(['dependency_overrides', package]);
      }
    }

    await pubspecFile.writeAsString(editor.toString());
  }

  /// Check if a package override exists in pubspec.yaml
  static Future<bool> hasOverride({
    required String pubspecPath,
    required String packageName,
  }) async {
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) return false;

    try {
      final content = await pubspecFile.readAsString();
      final doc = loadYaml(content) as Map?;
      final overrides = doc?['dependency_overrides'] as Map?;
      return overrides?.containsKey(packageName) ?? false;
    } on Exception {
      return false;
    }
  }

  /// Get all current dependency overrides from pubspec.yaml
  static Future<Map<String, String>> getOverrides({
    required String pubspecPath,
  }) async {
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) return {};

    try {
      final content = await pubspecFile.readAsString();
      final doc = loadYaml(content) as Map?;
      final overrides = doc?['dependency_overrides'] as Map? ?? {};
      return overrides.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on Exception {
      return {};
    }
  }
}

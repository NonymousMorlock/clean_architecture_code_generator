import 'dart:io';

import 'package:path/path.dart' as path;

/// {@template snapshot_manager}
/// Manages snapshots of generated files in the .dart_tool directory.
/// These snapshots serve as the "BASE" for 3-way merging.
/// {@endtemplate}
class SnapshotManager {
  /// {@macro snapshot_manager}
  SnapshotManager();

  static const String _snapshotDir = '.dart_tool/clean_arch_gen/snapshots';

  /// Saves a snapshot of the generated content.
  void saveSnapshot(String filePath, String content) {
    final snapshotPath = _getSnapshotPath(filePath);
    File(snapshotPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  /// Retrieves the snapshot for the given file path.
  /// Returns null if no snapshot exists.
  String? getSnapshot(String filePath) {
    final snapshotPath = _getSnapshotPath(filePath);
    final file = File(snapshotPath);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
    return null;
  }

  String _getSnapshotPath(String filePath) {
    // We want to mirror the project structure inside our snapshot directory
    // filePath is usually relative to project root (e.g., lib/features/...)
    return path.join(_snapshotDir, filePath);
  }
}

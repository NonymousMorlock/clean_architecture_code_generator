import 'dart:io';

import 'package:clean_arch_cli/src/utils/pubspec_editor.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('PubspecEditor', () {
    late Directory tempDir;
    late String pubspecPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pubspec_editor_test_');
      pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('addDependencyOverrides', () {
      test('creates dependency_overrides section when none exists', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.addDependencyOverrides(
          pubspecPath: pubspecPath,
          overrides: {'analyzer': '^9.0.0'},
        );

        final content = await File(pubspecPath).readAsString();
        expect(content, contains('dependency_overrides:'));
        expect(content, contains('analyzer: ^9.0.0'));
      });

      test('merges with existing dependency_overrides section', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter

dependency_overrides:
  http: ^1.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.addDependencyOverrides(
          pubspecPath: pubspecPath,
          overrides: {'analyzer': '^9.0.0'},
        );

        final content = await File(pubspecPath).readAsString();
        expect(content, contains('http: ^1.0.0'));
        expect(content, contains('analyzer: ^9.0.0'));
      });

      test('updates existing override when duplicate package', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter

dependency_overrides:
  analyzer: ^8.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.addDependencyOverrides(
          pubspecPath: pubspecPath,
          overrides: {'analyzer': '^9.0.0'},
        );

        final content = await File(pubspecPath).readAsString();
        expect(content, contains('analyzer: ^9.0.0'));
        expect(content, isNot(contains('^8.0.0')));
      });

      test('sorts overrides alphabetically', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter

dependency_overrides:
  http: ^1.0.0
  yaml: ^3.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.addDependencyOverrides(
          pubspecPath: pubspecPath,
          overrides: {
            'analyzer': '^9.0.0',
            'collection': '^2.0.0',
          },
        );

        final content = await File(pubspecPath).readAsString();
        final lines = content.split('\n');

        // Find the dependency_overrides section
        final overridesStart = lines.indexWhere(
          (line) => line.trim() == 'dependency_overrides:',
        );
        expect(overridesStart, greaterThanOrEqualTo(0));

        // Extract override entries
        final overrideLines = <String>[];
        for (var i = overridesStart + 1; i < lines.length; i++) {
          if (lines[i].startsWith('  ') &&
              lines[i].contains(':') &&
              lines[i].trim().isNotEmpty) {
            overrideLines.add(lines[i].trim());
          } else if (lines[i].trim().isNotEmpty && !lines[i].startsWith('  ')) {
            break;
          }
        }

        // Verify alphabetical order
        expect(overrideLines.length, equals(4));
        expect(overrideLines[0], startsWith('analyzer:'));
        expect(overrideLines[1], startsWith('collection:'));
        expect(overrideLines[2], startsWith('http:'));
        expect(overrideLines[3], startsWith('yaml:'));
      });

      test('preserves comments and formatting', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

# Important dependencies
dependencies:
  flutter:
    sdk: flutter

# Override for testing
dependency_overrides:
  http: ^1.0.0  # Keep this version
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.addDependencyOverrides(
          pubspecPath: pubspecPath,
          overrides: {'analyzer': '^9.0.0'},
        );

        final content = await File(pubspecPath).readAsString();
        expect(content, contains('# Important dependencies'));
        expect(content, contains('# Override for testing'));
        // Note: inline comments may or may not be preserved by yaml_edit
      });

      test('handles missing pubspec.yaml gracefully', () async {
        expect(
          () => PubspecEditor.addDependencyOverrides(
            pubspecPath: pubspecPath,
            overrides: {'analyzer': '^9.0.0'},
          ),
          throwsA(isA<FileSystemException>()),
        );
      });

      test('handles invalid YAML gracefully', () async {
        const invalidYaml = '''
name: test_app
  invalid indentation:
    - this is broken
''';
        await File(pubspecPath).writeAsString(invalidYaml);

        expect(
          () => PubspecEditor.addDependencyOverrides(
            pubspecPath: pubspecPath,
            overrides: {'analyzer': '^9.0.0'},
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('verifies no duplicate entries in final output', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter

dependency_overrides:
  analyzer: ^8.0.0
  http: ^1.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.addDependencyOverrides(
          pubspecPath: pubspecPath,
          overrides: {'analyzer': '^9.0.0', 'http': '^1.1.0'},
        );

        final content = await File(pubspecPath).readAsString();
        final analyzerMatches = 'analyzer:'.allMatches(content).length;
        final httpMatches = 'http:'.allMatches(content).length;

        expect(analyzerMatches, equals(1));
        expect(httpMatches, equals(1));
      });

      test('handles empty overrides map', () async {
        const initialContent = '''
name: test_app
version: 1.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.addDependencyOverrides(
          pubspecPath: pubspecPath,
          overrides: {},
        );

        final content = await File(pubspecPath).readAsString();
        expect(content, equals(initialContent));
      });

      test('handles multiple package updates in one call', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.addDependencyOverrides(
          pubspecPath: pubspecPath,
          overrides: {
            'analyzer': '^9.0.0',
            'collection': '^2.0.0',
            'http': '^1.0.0',
          },
        );

        final content = await File(pubspecPath).readAsString();
        expect(content, contains('analyzer: ^9.0.0'));
        expect(content, contains('collection: ^2.0.0'));
        expect(content, contains('http: ^1.0.0'));
      });
    });

    group('removeDependencyOverrides', () {
      test('removes specific packages from overrides', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependency_overrides:
  analyzer: ^9.0.0
  http: ^1.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        await PubspecEditor.removeDependencyOverrides(
          pubspecPath: pubspecPath,
          packages: ['analyzer'],
        );

        final content = await File(pubspecPath).readAsString();
        expect(content, isNot(contains('analyzer')));
        expect(content, contains('http: ^1.0.0'));
      });

      test(
        'removes entire dependency_overrides section when empty list',
        () async {
          const initialContent = '''
name: test_app
version: 1.0.0

dependency_overrides:
  analyzer: ^9.0.0
''';
          await File(pubspecPath).writeAsString(initialContent);

          await PubspecEditor.removeDependencyOverrides(
            pubspecPath: pubspecPath,
          );

          final content = await File(pubspecPath).readAsString();
          expect(content, isNot(contains('dependency_overrides:')));
        },
      );
    });

    group('hasOverride', () {
      test('returns true when package override exists', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependency_overrides:
  analyzer: ^9.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        final result = await PubspecEditor.hasOverride(
          pubspecPath: pubspecPath,
          packageName: 'analyzer',
        );

        expect(result, isTrue);
      });

      test('returns false when package override does not exist', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependency_overrides:
  http: ^1.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        final result = await PubspecEditor.hasOverride(
          pubspecPath: pubspecPath,
          packageName: 'analyzer',
        );

        expect(result, isFalse);
      });

      test('returns false when file does not exist', () async {
        final result = await PubspecEditor.hasOverride(
          pubspecPath: pubspecPath,
          packageName: 'analyzer',
        );

        expect(result, isFalse);
      });
    });

    group('getOverrides', () {
      test('returns all overrides', () async {
        const initialContent = '''
name: test_app
version: 1.0.0

dependency_overrides:
  analyzer: ^9.0.0
  http: ^1.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        final overrides = await PubspecEditor.getOverrides(
          pubspecPath: pubspecPath,
        );

        expect(overrides, equals({'analyzer': '^9.0.0', 'http': '^1.0.0'}));
      });

      test('returns empty map when no overrides exist', () async {
        const initialContent = '''
name: test_app
version: 1.0.0
''';
        await File(pubspecPath).writeAsString(initialContent);

        final overrides = await PubspecEditor.getOverrides(
          pubspecPath: pubspecPath,
        );

        expect(overrides, isEmpty);
      });

      test('returns empty map when file does not exist', () async {
        final overrides = await PubspecEditor.getOverrides(
          pubspecPath: pubspecPath,
        );

        expect(overrides, isEmpty);
      });
    });
  });
}

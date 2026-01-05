import 'package:clean_arch_cli/src/utils/pub_conflict_parser.dart';
import 'package:test/test.dart';

void main() {
  group('PubConflictParser', () {
    group('parse', () {
      test('returns non-conflict for non-conflict errors', () {
        const stderr = 'Error: File not found';
        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isFalse);
        expect(result.conflicts, isEmpty);
        expect(result.rootCause, isNull);
        expect(result.suggestedOverrides, isEmpty);
        expect(result.canAutoResolve, isFalse);
      });

      test('returns non-conflict for empty input', () {
        const stderr = '';
        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isFalse);
        expect(result.conflicts, isEmpty);
      });

      test('parses real analyzer conflict from issue example', () {
        const stderr = '''
Because test >=1.26.3 <1.27.0 depends on analyzer >=6.0.0 <9.0.0 and test >=1.25.9 <1.26.3 depends on analyzer >=6.0.0 <8.0.0, test >=1.25.9 <1.27.0 requires analyzer >=6.0.0 <9.0.0.
And because test >=1.24.4 <1.25.9 depends on analyzer >=5.12.0 <7.0.0, test >=1.24.4 <1.27.0 requires analyzer >=5.12.0 <9.0.0.
(1) So, because test >=1.21.6 <1.24.4 depends on analyzer >=2.0.0 <6.0.0 and test >=1.21.0 <1.21.6 depends on analyzer >=2.0.0 <5.0.0, test >=1.21.0 <1.27.0 requires analyzer >=2.0.0 <9.0.0.

Because test >=1.16.6 <1.17.10 depends on analyzer ^1.0.0 and test >=1.17.10 <1.20.0 depends on analyzer >=1.0.0 <3.0.0, test >=1.16.6 <1.20.0 requires analyzer >=1.0.0 <3.0.0.
And because test >=1.20.0 <1.21.2 depends on test_api 0.4.9, test >=1.16.6 <1.21.2 requires test_api 0.4.9 or analyzer >=1.0.0 <3.0.0.
And because test >=1.21.0 <1.27.0 requires analyzer >=2.0.0 <9.0.0 (1), test >=1.16.6 <1.27.0 requires analyzer >=1.0.0 <9.0.0 or test_api 0.4.9.
And because every version of generators from git depends on analyzer ^9.0.0 and test >=1.27.0 depends on test_api 0.7.8, if generators from git and test >=1.16.6 then test_api 0.4.9 or 0.7.8.
And because test >=1.16.0-nullsafety.19 <1.16.6 depends on test_api 0.2.19 and every version of flutter_test from sdk depends on test_api 0.7.7, one of generators from git or test >=1.16.0-nullsafety.19 or flutter_test from sdk must be false.
And because forge_deck depends on bloc_test ^10.0.0 which depends on test ^1.16.0, generators from git is incompatible with flutter_test from sdk.
So, because forge_deck depends on both flutter_test from sdk and generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        expect(result.conflicts, isNotEmpty);
        expect(result.rootCause, equals('generators'));
        expect(result.suggestedOverrides, isNotEmpty);
        expect(result.canAutoResolve, isTrue);
        expect(result.suggestedOverrides['analyzer'], equals('^9.0.0'));
      });

      test('identifies generators as root cause', () {
        const stderr = '''
And because every version of generators from git depends on analyzer ^9.0.0 and test >=1.27.0 depends on test_api 0.7.8, if generators from git and test >=1.16.6 then test_api 0.4.9 or 0.7.8.
So, because forge_deck depends on both flutter_test from sdk and generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        expect(result.rootCause, equals('generators'));
      });

      test('extracts analyzer as conflicting package', () {
        const stderr = '''
Because every version of generators from git depends on analyzer ^9.0.0 and test >=1.26.3 depends on analyzer >=6.0.0 <9.0.0, generators from git is incompatible with test >=1.26.3.
So, because myapp depends on both test ^1.26.3 and generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        expect(
          result.conflicts.any((c) => c.packageName == 'analyzer'),
          isTrue,
        );
      });

      test('extracts ^9.0.0 as required version', () {
        const stderr = '''
Because every version of generators from git depends on analyzer ^9.0.0, generators from git requires analyzer ^9.0.0.
So, because myapp depends on generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.suggestedOverrides['analyzer'], equals('^9.0.0'));
      });

      test('handles simple single-package conflict', () {
        const stderr = '''
Because myapp depends on package_a ^2.0.0 which depends on shared ^3.0.0 and myapp depends on package_b ^1.0.0 which depends on shared ^2.0.0, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        expect(result.conflicts, isNotEmpty);
      });

      test('handles multiple conflicting packages', () {
        const stderr = '''
Because generators from git depends on analyzer ^9.0.0 and generators from git depends on collection ^2.0.0, generators from git requires analyzer ^9.0.0 and collection ^2.0.0.
So, because myapp depends on generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        expect(result.conflicts.length, greaterThanOrEqualTo(1));
      });

      test('handles malformed error messages gracefully', () {
        const stderr = '''
This is not a properly formatted conflict error
version solving failed
but it has random text
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        // Should still detect it's a conflict but may not parse details
      });

      test('handles version range format >=X.Y.Z <A.B.C', () {
        const stderr = '''
Because generators from git depends on analyzer >=9.0.0 <10.0.0, generators from git requires analyzer >=9.0.0 <10.0.0.
So, because myapp depends on generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        expect(result.suggestedOverrides['analyzer'], equals('^9.0.0'));
      });

      test('handles exact version format X.Y.Z', () {
        const stderr = '''
Because generators from git depends on analyzer 9.0.0, generators from git requires analyzer 9.0.0.
So, because myapp depends on generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        expect(result.suggestedOverrides['analyzer'], equals('9.0.0'));
      });

      test('identifies git dependency source correctly', () {
        const stderr = '''
Because every version of my_package from git depends on some_dep ^1.0.0, my_package from git requires some_dep ^1.0.0.
So, because myapp depends on my_package from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.rootCause, equals('my_package'));
      });

      test('handles network error as non-conflict', () {
        const stderr = '''
Error connecting to https://github.com/example/repo.git
Failed to fetch repository
Connection timeout
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isFalse);
      });

      test('handles multiple "from git" packages', () {
        const stderr = '''
Because package_a from git depends on shared ^3.0.0 and package_b from git depends on shared ^2.0.0, one of package_a from git or package_b from git must be false.
So, because myapp depends on both package_a from git and package_b from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
        expect(result.rootCause, isNotNull);
      });

      test('preserves raw error in result', () {
        const stderr = 'Some error message';
        final result = PubConflictParser.parse(stderr);

        expect(result.rawError, equals(stderr));
      });

      test('handles "is incompatible with" pattern', () {
        const stderr = '''
Because generators from git depends on analyzer ^9.0.0, generators from git is incompatible with analyzer <9.0.0.
So, because myapp depends on both analyzer ^8.0.0 and generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
      });

      test('handles "requires" pattern', () {
        const stderr = '''
Because test >=1.26.3 requires analyzer >=6.0.0 and generators from git depends on analyzer ^9.0.0, generators from git is incompatible with test >=1.26.3.
So, because myapp depends on both test >=1.26.3 and generators from git, version solving failed.
''';

        final result = PubConflictParser.parse(stderr);

        expect(result.isConflict, isTrue);
      });
    });
  });
}

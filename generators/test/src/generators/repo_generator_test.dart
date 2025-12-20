import 'package:generators/src/generators/repo_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('RepoGenerator Golden Tests', () {
    test('generates AuthRepo from AuthRepoTBG', () async {
      await testGolden(
        inputFileName: 'auth_repository_tbg.dart',
        goldenFileName: 'auth.repository.g.dart',
        builder: PartBuilder([RepoGenerator()], '.g.dart'),
      );
    });
  });
}

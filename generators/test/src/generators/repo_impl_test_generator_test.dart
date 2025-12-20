import 'package:generators/src/generators/repo_impl_test_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('RepoImplTestGenerator Golden Tests', () {
    test('generates AuthRepoImplTest from AuthRepoTBG', () async {
      await testGolden(
        inputFileName: 'auth_repository_tbg.dart',
        goldenFileName: 'auth.repository_impl_test.g.dart',
        builder: PartBuilder([RepoImplTestGenerator()], '.g.dart'),
      );
    });
  });
}

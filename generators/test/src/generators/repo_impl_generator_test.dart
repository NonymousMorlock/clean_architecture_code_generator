import 'package:generators/src/generators/repo_impl_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('RepoImplGenerator Golden Tests', () {
    test('generates AuthRepoImpl from AuthRepoTBG', () async {
      await testGolden(
        inputFileName: 'auth_repository_tbg.dart',
        goldenFileName: 'auth.repository_impl.g.dart',
        builder: PartBuilder([RepoImplGenerator()], '.g.dart'),
      );
    });
  });
}

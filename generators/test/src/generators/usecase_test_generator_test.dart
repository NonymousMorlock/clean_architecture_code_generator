import 'package:generators/src/generators/usecase_test_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('UseCaseTestGenerator Golden Tests', () {
    test('generates AuthUseCaseTest from AuthRepoTBG', () async {
      await testGolden(
        inputFileName: 'auth_repository_tbg.dart',
        goldenFileName: 'auth.usecase_test.g.dart',
        builder: PartBuilder([UsecaseTestGenerator()], '.g.dart'),
      );
    });
  });
}

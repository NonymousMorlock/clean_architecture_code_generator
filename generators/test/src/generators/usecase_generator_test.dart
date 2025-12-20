import 'package:generators/src/generators/usecase_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('UseCaseGenerator Golden Tests', () {
    test('generates Auth use cases from AuthRepoTBG', () async {
      await testGolden(
        inputFileName: 'auth_repository_tbg.dart',
        goldenFileName: 'auth.usecase.g.dart',
        builder: PartBuilder([UsecaseGenerator()], '.g.dart'),
      );
    });
  });
}

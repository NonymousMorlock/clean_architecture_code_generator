import 'package:generators/src/generators/model_test_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('ModelTestGenerator Golden Tests', () {
    test('generates UserModelTest from UserTBG', () async {
      await testGolden(
        inputFileName: 'user_model_tbg.dart',
        goldenFileName: 'user.model_test.g.dart',
        builder: PartBuilder([ModelTestGenerator()], '.g.dart'),
      );
    });
  });
}

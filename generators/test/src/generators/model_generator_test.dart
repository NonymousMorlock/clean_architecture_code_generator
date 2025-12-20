import 'package:generators/src/generators/model_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('ModelGenerator Golden Tests', () {
    test('generates UserModel from UserTBG', () async {
      await testGolden(
        inputFileName: 'user_model_tbg.dart',
        goldenFileName: 'user.model.g.dart',
        builder: PartBuilder([ModelGenerator()], '.g.dart'),
      );
    });
  });
}

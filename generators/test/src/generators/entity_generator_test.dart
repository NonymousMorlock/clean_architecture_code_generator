import 'package:generators/src/generators/entity_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('EntityGenerator Golden Tests', () {
    test('generates User entity from UserTBG', () async {
      await testGolden(
        inputFileName: 'user_model_tbg.dart',
        goldenFileName: 'user.entity.g.dart',
        builder: PartBuilder([EntityGenerator()], '.g.dart'),
      );
    });
  });
}

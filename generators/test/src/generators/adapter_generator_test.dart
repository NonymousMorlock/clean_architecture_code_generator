import 'package:generators/src/generators/adapter_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('AdapterGenerator Golden Tests', () {
    test('generates AuthAdapter from AuthRepoTBG', () async {
      await testGolden(
        inputFileName: 'auth_repository_tbg.dart',
        goldenFileName: 'auth.adapter.g.dart',
        builder: PartBuilder([AdapterGenerator()], '.g.dart'),
      );
    });
  });
}

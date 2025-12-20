import 'package:generators/src/generators/remote_data_src_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import '../../utils/golden_utils.dart';

void main() {
  group('RemoteDataSrcGenerator Golden Tests', () {
    test('generates AuthRemoteDataSrc from AuthRepoTBG', () async {
      await testGolden(
        inputFileName: 'auth_repository_tbg.dart',
        goldenFileName: 'auth.remote_data_src.g.dart',
        builder: PartBuilder([RemoteDataSrcGenerator()], '.g.dart'),
      );
    });
  });
}

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Runs the [builder] against the [inputFileName] and compares the result
/// to the [goldenFileName].
Future<void> testGolden({
  required String inputFileName,
  required String goldenFileName,
  required Builder builder,
  String? reason,
}) async {
  final isUpdateMode = Platform.environment['UPDATE_GOLDENS'] == 'true';

  // 1. Read the Input File from disk
  final inputPath = p.join('test', 'goldens', 'inputs', inputFileName);
  final inputSource = File(inputPath).readAsStringSync();

  // 2. Define the Asset ID for the input (simulated file system)
  final inputId = 'generators|lib/$inputFileName';

  // 3. Run the Generator using build_test
  final writer = InMemoryAssetWriter();
  await testBuilder(
    builder,
    {inputId: inputSource},
    writer: writer,
    reader: await PackageAssetReader.currentIsolate(),
  );

  // 4. Capture the actual output
  if (writer.assets.isEmpty) {
    fail('Generator produced no output for $inputFileName');
  }

  final actualOutputAssetId = writer.assets.keys.first;
  var actualOutput = String.fromCharCodes(writer.assets[actualOutputAssetId]!);

  // 5. Normalization
  actualOutput = _normalize(actualOutput);

  // 6. Handle Golden Comparison / Update
  final goldenPath = p.join('test', 'goldens', 'outputs', goldenFileName);
  final goldenFile = File(goldenPath);

  if (isUpdateMode) {
    if (!goldenFile.parent.existsSync()) {
      goldenFile.parent.createSync(recursive: true);
    }
    goldenFile.writeAsStringSync(actualOutput);
    return;
  }

  if (!goldenFile.existsSync()) {
    fail(
      'Golden file not found at $goldenPath. '
      'Run with UPDATE_GOLDENS=true to create it.',
    );
  }

  final expectedOutput = _normalize(goldenFile.readAsStringSync());

  // We use equals() here instead of decodedMatches() because actualOutput
  // is already a normalized String, not a List<int>.
  expect(
    actualOutput,
    equals(expectedOutput),
    reason:
        reason ??
        'Generated output for $inputFileName does not match $goldenFileName',
  );
}

String _normalize(String content) {
  return content
      .replaceAll('\r\n', '\n')
      .split('\n')
      .where((line) {
        final l = line.trim();
        return l.isNotEmpty &&
            !l.startsWith('//') && // Remove all comments (headers)
            !l.startsWith('part of'); // Remove part-of for cleaner diffs
      })
      .join('\n')
      .trim();
}

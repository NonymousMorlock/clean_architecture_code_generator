import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart'; // Required for LibraryElement
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:package_config/package_config.dart'; // Required for PackageConfig
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

  // Setup Input
  final inputPath = p.join('test', 'goldens', 'inputs', inputFileName);
  final inputSource = File(inputPath).readAsStringSync();
  final inputId = AssetId('generators', 'lib/$inputFileName');

  // Setup the "Real" ReaderWriter (Required by testBuilder internals)
  final readerWriter = TestReaderWriter(rootPackage: 'generators');
  await readerWriter.testing.loadIsolateSources();

  // Wrap the Builder to capture outputs
  final capturingBuilder = _CapturingBuilder(builder);

  // Run the Builder
  await testBuilder(
    capturingBuilder,
    {inputId.toString(): inputSource},
    readerWriter: readerWriter,
    rootPackage: 'generators',
  );

  // Determine expected output ID
  // Note: Adjust extension if your builder outputs something else (e.g. .part)
  final expectedOutputId = inputId.changeExtension('.g.dart');

  // Retrieve the Output from our Capture Map
  final generatedBytes = capturingBuilder.capturedAssets[expectedOutputId];

  if (generatedBytes == null) {
    final written = capturingBuilder.capturedAssets.keys
        .map((e) => e.path)
        .join(', ');
    fail(
      'Generator finished but did not output ${expectedOutputId.path}. '
      '\nWritten assets: [$written]',
    );
  }

  // Decode and Compare
  final actualOutput = utf8.decode(generatedBytes);

  _compareAndWrite(
    actualOutput: actualOutput,
    goldenFileName: goldenFileName,
    inputFileName: inputFileName,
    isUpdateMode: isUpdateMode,
    reason: reason,
  );
}

void _compareAndWrite({
  required String actualOutput,
  required String goldenFileName,
  required String inputFileName,
  required bool isUpdateMode,
  required String? reason,
}) {
  actualOutput = _normalize(actualOutput);
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
    fail('Golden file not found at $goldenPath. Run with UPDATE_GOLDENS=true.');
  }

  final expectedOutput = _normalize(goldenFile.readAsStringSync());

  expect(
    actualOutput,
    equals(expectedOutput),
    reason:
        reason ?? 'Generated output for $inputFileName does not match golden.',
  );
}

String _normalize(String content) {
  return content
      .replaceAll('\r\n', '\n')
      .split('\n')
      .where((line) {
        final l = line.trim();
        return l.isNotEmpty && !l.startsWith('//') && !l.startsWith('part of');
      })
      .join('\n')
      .trim();
}

/// Wraps a [Builder] to capture assets written to the [BuildStep].
class _CapturingBuilder implements Builder {
  _CapturingBuilder(this._delegate);

  final Builder _delegate;
  final Map<AssetId, List<int>> capturedAssets = {};

  @override
  Map<String, List<String>> get buildExtensions => _delegate.buildExtensions;

  @override
  Future<void> build(BuildStep buildStep) async {
    // Wrap the BuildStep to intercept writes
    final proxyStep = _CapturingBuildStep(buildStep, capturedAssets);
    await _delegate.build(proxyStep);
  }
}

/// Proxies a [BuildStep] to capture writes into a local Map.
class _CapturingBuildStep implements BuildStep {
  _CapturingBuildStep(this._delegate, this._capturedAssets);

  final BuildStep _delegate;
  final Map<AssetId, List<int>> _capturedAssets;

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) async {
    _capturedAssets[id] = await bytes;
    await _delegate.writeAsBytes(id, bytes);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> contents, {
    Encoding encoding = utf8,
  }) async {
    _capturedAssets[id] = encoding.encode(await contents);
    await _delegate.writeAsString(id, contents, encoding: encoding);
  }

  @override
  AssetId get inputId => _delegate.inputId;

  @override
  Future<bool> canRead(AssetId id) => _delegate.canRead(id);

  @override
  Future<List<int>> readAsBytes(AssetId id) => _delegate.readAsBytes(id);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) =>
      _delegate.readAsString(id, encoding: encoding);

  @override
  Stream<AssetId> findAssets(Glob glob) => _delegate.findAssets(glob);

  @override
  Resolver get resolver => _delegate.resolver;

  @override
  Future<T> fetchResource<T>(Resource<T> resource) =>
      _delegate.fetchResource(resource);

  @override
  Future<Digest> digest(AssetId id) => _delegate.digest(id);

  @override
  void reportUnusedAssets(Iterable<AssetId> assets) =>
      _delegate.reportUnusedAssets(assets);

  @override
  T trackStage<T>(
    String label,
    T Function() action, {
    bool isExternal = false,
  }) => _delegate.trackStage(label, action, isExternal: isExternal);

  @override
  Iterable<AssetId> get allowedOutputs => _delegate.allowedOutputs;

  @override
  Future<LibraryElement> get inputLibrary => _delegate.inputLibrary;

  @override
  Future<PackageConfig> get packageConfig => _delegate.packageConfig;
}

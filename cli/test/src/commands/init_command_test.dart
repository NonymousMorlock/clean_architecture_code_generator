import 'dart:io';

import 'package:clean_arch_cli/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('init', () {
    late Logger logger;
    late CliCommandRunner commandRunner;
    late Directory tempDir;

    setUp(() {
      logger = _MockLogger();
      commandRunner = CliCommandRunner(logger: logger);
      tempDir = Directory.systemTemp.createTempSync('init_test_');

      when(() => logger.info(any())).thenAnswer((_) {});
      when(() => logger.success(any())).thenAnswer((_) {});
      when(() => logger.detail(any())).thenAnswer((_) {});
      when(() => logger.err(any())).thenAnswer((_) {});
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<void> writePubspec({required String appName}) async {
      final pubspec = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspec.writeAsString('name: $appName\n');
    }

    test('can be instantiated', () {
      expect(commandRunner.commands['init'], isNotNull);
    });

    test('fails when pubspec.yaml is missing', () async {
      final result = await commandRunner.run([
        'init',
        '--output',
        tempDir.path,
        '--no-with-examples',
      ]);

      expect(result, equals(ExitCode.ioError.code));
      verify(
        () => logger.err(any(that: contains('Could not find pubspec.yaml'))),
      ).called(1);
    });

    test('creates core files and config using templates', () async {
      await writePubspec(appName: 'test_app');

      final result = await commandRunner.run([
        'init',
        '--output',
        tempDir.path,
        '--no-with-examples',
      ]);

      expect(result, equals(ExitCode.success.code));

      final libPath = path.join(tempDir.path, 'lib');
      expect(
        File(
          path.join(libPath, 'core', 'errors', 'failures.dart'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          path.join(libPath, 'core', 'errors', 'exceptions.dart'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          path.join(libPath, 'core', 'usecases', 'usecase.dart'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(path.join(libPath, 'core', 'typedefs.dart')).existsSync(),
        isTrue,
      );
      expect(
        File(path.join(tempDir.path, 'clean_arch_config.yaml')).existsSync(),
        isTrue,
      );

      final typedefsContent = await File(
        path.join(libPath, 'core', 'typedefs.dart'),
      ).readAsString();
      expect(
        typedefsContent,
        contains('package:test_app/core/errors/failures.dart'),
      );
    });

    test('appends typedefs when file already exists', () async {
      await writePubspec(appName: 'test_app');
      final libPath = path.join(tempDir.path, 'lib');
      final typedefsFile = File(path.join(libPath, 'core', 'typedefs.dart'));
      await typedefsFile.create(recursive: true);
      await typedefsFile.writeAsString('typedef Existing = String;');

      final result = await commandRunner.run([
        'init',
        '--output',
        tempDir.path,
        '--no-with-examples',
      ]);

      expect(result, equals(ExitCode.success.code));

      final content = await typedefsFile.readAsString();
      expect(content, contains('typedef Existing = String;'));
      expect(content, contains('ResultFuture<'));
    });

    test('skips overwriting existing non-append files', () async {
      await writePubspec(appName: 'test_app');
      final libPath = path.join(tempDir.path, 'lib');
      final usecaseFile = File(
        path.join(libPath, 'core', 'usecases', 'usecase.dart'),
      );
      await usecaseFile.create(recursive: true);
      const customContent = 'custom usecase content';
      await usecaseFile.writeAsString(customContent);

      final result = await commandRunner.run([
        'init',
        '--output',
        tempDir.path,
        '--no-with-examples',
      ]);

      expect(result, equals(ExitCode.success.code));
      final content = await usecaseFile.readAsString();
      expect(content, equals(customContent));
      verify(
        () => logger.detail(
          any<String>(
            that: predicate<String>(
              (value) => value.contains('usecases/usecase.dart'),
            ),
          ),
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    test('creates sample TBG files with safe naming', () async {
      await writePubspec(appName: 'test_app');

      final result = await commandRunner.run([
        'init',
        '--output',
        tempDir.path,
        '--with-examples',
      ]);

      expect(result, equals(ExitCode.success.code));

      final sampleDir = path.join(tempDir.path, 'lib', 'src', 'sample', 'tbg');
      final sampleFiles = Directory(
        sampleDir,
      ).listSync().whereType<File>().map((f) => path.basename(f.path)).toList();

      expect(sampleFiles, contains('sample_tbg.dart'));
      expect(sampleFiles, contains('sample_tbg_2.dart'));
    });
  });
}

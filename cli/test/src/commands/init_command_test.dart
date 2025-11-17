import 'dart:io';

import 'package:cli/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('init', () {
    late Logger logger;
    late CliCommandRunner commandRunner;
    late Directory tempDir;

    setUp(() {
      logger = _MockLogger();
      commandRunner = CliCommandRunner(logger: logger);

      // Create a temporary directory for testing
      tempDir = Directory.systemTemp.createTempSync('init_test_');

      // Mock progress
      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((_) {});
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => logger.info(any())).thenAnswer((_) {});
      when(() => logger.success(any())).thenAnswer((_) {});
      when(() => logger.detail(any())).thenAnswer((_) {});
      when(() => logger.err(any())).thenAnswer((_) {});
    });

    tearDown(() {
      // Clean up temp directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('can be instantiated', () {
      expect(
        commandRunner.commands['init'],
        isNotNull,
      );
    });

    test('requires project-name option', () async {
      expect(
        () => commandRunner.run([
          'init',
          '--output',
          tempDir.path,
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'creates Flutter project with clean architecture structure',
      () async {
        const projectName = 'test_project';
        final projectPath = path.join(tempDir.path, projectName);

        // Skip this test if Flutter is not installed
        final flutterCheck = await Process.run('which', ['flutter']);
        if (flutterCheck.exitCode != 0) {
          markTestSkipped('Flutter not installed');
          return;
        }

        final result = await commandRunner.run([
          'init',
          '--project-name',
          projectName,
          '--output',
          tempDir.path,
          '--no-with-examples',
        ]);

        expect(result, equals(ExitCode.success.code));

        // Verify project directory was created
        expect(Directory(projectPath).existsSync(), isTrue);

        // Verify core directories exist
        final libPath = path.join(projectPath, 'lib');
        expect(
          Directory(path.join(libPath, 'core', 'constants')).existsSync(),
          isTrue,
        );
        expect(
          Directory(path.join(libPath, 'core', 'errors')).existsSync(),
          isTrue,
        );
        expect(
          Directory(path.join(libPath, 'core', 'usecases')).existsSync(),
          isTrue,
        );

        // Verify core files exist
        expect(
          File(path.join(libPath, 'core', 'typedefs.dart')).existsSync(),
          isTrue,
        );
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

        // Verify logger calls
        verify(
          () => logger.info(
            '🚀 Initializing Flutter project with clean architecture...',
          ),
        ).called(1);
        verify(() => logger.success('✅ Flutter project created')).called(1);
        verify(
          () => logger.success(
            '🎉 Clean architecture project initialized successfully!',
          ),
        ).called(1);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'creates example files when with-examples is true',
      () async {
        const projectName = 'test_project_with_examples';
        final projectPath = path.join(tempDir.path, projectName);

        // Skip this test if Flutter is not installed
        final flutterCheck = await Process.run('which', ['flutter']);
        if (flutterCheck.exitCode != 0) {
          markTestSkipped('Flutter not installed');
          return;
        }

        final result = await commandRunner.run([
          'init',
          '--project-name',
          projectName,
          '--output',
          tempDir.path,
          '--with-examples',
        ]);

        expect(result, equals(ExitCode.success.code));

        // Verify example authentication feature exists
        final libPath = path.join(projectPath, 'lib');
        expect(
          Directory(
            path.join(
              libPath,
              'features',
              'authentication',
              'domain',
              'entities',
            ),
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            path.join(
              libPath,
              'features',
              'authentication',
              'domain',
              'entities',
              'user.dart',
            ),
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            path.join(
              libPath,
              'features',
              'authentication',
              'auth_repository_tbg.dart',
            ),
          ).existsSync(),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('handles Flutter create failure gracefully', () async {
      // Use a directory that doesn't have write permissions to force failure
      const projectName = 'test_project';
      const invalidOutput = '/root/no_permission_directory';

      // Skip this test if Flutter is not installed
      final flutterCheck = await Process.run('which', ['flutter']);
      if (flutterCheck.exitCode != 0) {
        markTestSkipped('Flutter not installed');
        return;
      }

      final result = await commandRunner.run([
        'init',
        '--project-name',
        projectName,
        '--output',
        invalidOutput,
      ]);

      expect(result, equals(ExitCode.software.code));
      verify(
        () =>
            logger.err(any(that: contains('Failed to create Flutter project'))),
      ).called(1);
    });

    test('uses default output directory when not specified', () async {
      // Test that the command accepts the default output directory
      // by checking the argument parser configuration
      final initCommand = commandRunner.commands['init'];
      expect(initCommand, isNotNull);

      // Verify that output option has a default value
      final outputOption = initCommand!.argParser.options['output'];
      expect(outputOption, isNotNull);
      expect(outputOption!.defaultsTo, equals('.'));
    });
  });
}

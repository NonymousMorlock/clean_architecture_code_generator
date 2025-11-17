import 'dart:io';

import 'package:cli/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('create', () {
    late Logger logger;
    late CliCommandRunner commandRunner;
    late Directory tempDir;

    setUp(() {
      logger = _MockLogger();
      commandRunner = CliCommandRunner(logger: logger);

      // Create a temporary directory for testing
      tempDir = Directory.systemTemp.createTempSync('create_test_');

      // Mock progress and logger
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
        commandRunner.commands['create'],
        isNotNull,
      );
    });

    test('requires type option', () async {
      expect(
        () => commandRunner.run([
          'create',
          '--name',
          'test',
          '--path',
          tempDir.path,
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('requires name option', () async {
      expect(
        () => commandRunner.run([
          'create',
          '--type',
          'feature',
          '--path',
          tempDir.path,
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('requires feature option for non-feature types', () async {
      final result = await commandRunner.run([
        'create',
        '--type',
        'entity',
        '--name',
        'user',
        '--path',
        tempDir.path,
      ]);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('❌ Feature name is required for entity creation'),
      ).called(1);
      verify(
        () => logger.info('Use --feature to specify the feature name'),
      ).called(1);
    });

    group('feature creation', () {
      test('creates feature directory structure', () async {
        const featureName = 'authentication';
        final libPath = path.join(tempDir.path, 'lib');

        final result = await commandRunner.run([
          'create',
          '--type',
          'feature',
          '--name',
          featureName,
          '--path',
          tempDir.path,
        ]);

        expect(result, equals(ExitCode.success.code));

        // Verify feature directories were created
        final featurePath = path.join(libPath, 'features', featureName);
        expect(Directory(featurePath).existsSync(), isTrue);

        // Verify subdirectories
        expect(
          Directory(path.join(featurePath, 'data', 'datasources')).existsSync(),
          isTrue,
        );
        expect(
          Directory(path.join(featurePath, 'data', 'models')).existsSync(),
          isTrue,
        );
        expect(
          Directory(
            path.join(featurePath, 'data', 'repositories'),
          ).existsSync(),
          isTrue,
        );
        expect(
          Directory(path.join(featurePath, 'domain', 'entities')).existsSync(),
          isTrue,
        );
        expect(
          Directory(
            path.join(featurePath, 'domain', 'repositories'),
          ).existsSync(),
          isTrue,
        );
        expect(
          Directory(path.join(featurePath, 'domain', 'usecases')).existsSync(),
          isTrue,
        );
        expect(
          Directory(
            path.join(featurePath, 'presentation', 'bloc'),
          ).existsSync(),
          isTrue,
        );

        verify(
          () => logger.info('🏗️  Creating feature: $featureName'),
        ).called(1);
        verify(
          () => logger.success('✅ feature created successfully!'),
        ).called(1);
      });
    });

    group('entity creation', () {
      test('creates entity file with correct content', () async {
        const featureName = 'authentication';
        const entityName = 'user';
        final libPath = path.join(tempDir.path, 'lib');

        // First create the feature structure
        await commandRunner.run([
          'create',
          '--type',
          'feature',
          '--name',
          featureName,
          '--path',
          tempDir.path,
        ]);

        final result = await commandRunner.run([
          'create',
          '--type',
          'entity',
          '--name',
          entityName,
          '--feature',
          featureName,
          '--path',
          tempDir.path,
        ]);

        expect(result, equals(ExitCode.success.code));

        // Verify entity file was created
        final entityPath = path.join(
          libPath,
          'features',
          featureName,
          'domain',
          'entities',
          '$entityName.dart',
        );
        expect(File(entityPath).existsSync(), isTrue);

        // Verify file content
        final content = File(entityPath).readAsStringSync();
        expect(content, contains('@entityGen'));
        expect(content, contains('@modelGen'));
        expect(content, contains('class UserTBG'));

        verify(
          () => logger.info('🏗️  Creating entity: $entityName'),
        ).called(1);
        verify(
          () => logger.success('✅ entity created successfully!'),
        ).called(1);
      });
    });

    group('repository creation', () {
      test('creates repository file with correct content', () async {
        const featureName = 'authentication';
        const repoName = 'auth';
        final libPath = path.join(tempDir.path, 'lib');

        // First create the feature structure
        await commandRunner.run([
          'create',
          '--type',
          'feature',
          '--name',
          featureName,
          '--path',
          tempDir.path,
        ]);

        final result = await commandRunner.run([
          'create',
          '--type',
          'repository',
          '--name',
          repoName,
          '--feature',
          featureName,
          '--path',
          tempDir.path,
        ]);

        expect(result, equals(ExitCode.success.code));

        // Verify repository file was created
        final repoPath = path.join(
          libPath,
          'features',
          featureName,
          'domain',
          'repositories',
          '${repoName}_repository.dart',
        );
        expect(File(repoPath).existsSync(), isTrue);

        // Verify file content
        final content = File(repoPath).readAsStringSync();
        expect(content, contains('@repoGen'));
        expect(content, contains('@usecaseGen'));
        expect(content, contains('@repoImplGen'));
        expect(content, contains('@remoteSrcGen'));
        expect(content, contains('class AuthRepoTBG'));

        verify(
          () => logger.info('🏗️  Creating repository: $repoName'),
        ).called(1);
        verify(
          () => logger.success('✅ repository created successfully!'),
        ).called(1);
      });
    });

    group('usecase creation', () {
      test('creates usecase file with correct content', () async {
        const featureName = 'authentication';
        const usecaseName = 'login';
        final libPath = path.join(tempDir.path, 'lib');

        // First create the feature structure
        await commandRunner.run([
          'create',
          '--type',
          'feature',
          '--name',
          featureName,
          '--path',
          tempDir.path,
        ]);

        final result = await commandRunner.run([
          'create',
          '--type',
          'usecase',
          '--name',
          usecaseName,
          '--feature',
          featureName,
          '--path',
          tempDir.path,
        ]);

        expect(result, equals(ExitCode.success.code));

        // Verify usecase file was created
        final usecasePath = path.join(
          libPath,
          'features',
          featureName,
          'domain',
          'usecases',
          '$usecaseName.dart',
        );
        expect(File(usecasePath).existsSync(), isTrue);

        // Verify file content
        final content = File(usecasePath).readAsStringSync();
        expect(content, contains('class Login extends UsecaseWithoutParams'));
        expect(content, contains('final AuthenticationRepo _repository'));

        verify(
          () => logger.info('🏗️  Creating usecase: $usecaseName'),
        ).called(1);
        verify(
          () => logger.success('✅ usecase created successfully!'),
        ).called(1);
      });
    });

    group('cubit creation', () {
      test('creates cubit and state files with correct content', () async {
        const featureName = 'authentication';
        const cubitName = 'auth';
        final libPath = path.join(tempDir.path, 'lib');

        // First create the feature structure
        await commandRunner.run([
          'create',
          '--type',
          'feature',
          '--name',
          featureName,
          '--path',
          tempDir.path,
        ]);

        final result = await commandRunner.run([
          'create',
          '--type',
          'cubit',
          '--name',
          cubitName,
          '--feature',
          featureName,
          '--path',
          tempDir.path,
        ]);

        expect(result, equals(ExitCode.success.code));

        // Verify cubit file was created
        final cubitPath = path.join(
          libPath,
          'features',
          featureName,
          'presentation',
          'bloc',
          '${cubitName}_cubit.dart',
        );
        expect(File(cubitPath).existsSync(), isTrue);

        // Verify state file was created
        final statePath = path.join(
          libPath,
          'features',
          featureName,
          'presentation',
          'bloc',
          '${cubitName}_state.dart',
        );
        expect(File(statePath).existsSync(), isTrue);

        // Verify cubit content
        final cubitContent = File(cubitPath).readAsStringSync();
        expect(cubitContent, contains('@cubitGen'));
        expect(cubitContent, contains('class AuthCubitTBG extends Cubit'));

        // Verify state content
        final stateContent = File(statePath).readAsStringSync();
        expect(stateContent, contains('sealed class AuthState'));
        expect(stateContent, contains('class AuthInitial'));
        expect(stateContent, contains('class AuthLoading'));
        expect(stateContent, contains('class AuthLoaded'));
        expect(stateContent, contains('class AuthError'));

        verify(() => logger.info('🏗️  Creating cubit: $cubitName')).called(1);
        verify(() => logger.success('✅ cubit created successfully!')).called(1);
      });
    });

    test('uses default path when not specified', () async {
      // Test that the command accepts the default path
      // by checking the argument parser configuration
      final createCommand = commandRunner.commands['create'];
      expect(createCommand, isNotNull);

      // Verify that path option has a default value
      final pathOption = createCommand!.argParser.options['path'];
      expect(pathOption, isNotNull);
      expect(pathOption!.defaultsTo, equals('.'));
    });

    test('shows help message after creation', () async {
      final result = await commandRunner.run([
        'create',
        '--type',
        'feature',
        '--name',
        'test',
        '--path',
        tempDir.path,
      ]);

      expect(result, equals(ExitCode.success.code));
      verify(
        () => logger.info('🔧 Run "clean_arch_cli generate" to generate code'),
      ).called(1);
    });
  });
}

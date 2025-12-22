class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRemoteDataSource remoteDataSource;
  late AuthRepoImpl repoImpl;
  setUp(() {
    remoteDataSource = MockAuthRemoteDataSource();
    repoImpl = AuthRepoImpl(remoteDataSource);
  });
  const serverFailure = ServerFailure(
    message: 'Something went wrong',
    statusCode: 500,
  );
  group('confirmSignup', () {
    const tIdentifier = 'Test String';
    const tOtp = 'Test String';
    test('should complete successfully when call  '
        'to remote source is successful', () async {
      when(() {
        return remoteDataSource.confirmSignup(
          identifier: any<String>(named: 'identifier'),
          otp: any<String>(named: 'otp'),
        );
      }).thenAnswer((_) async => Future.value());
      final result = await repoImpl.confirmSignup(
        identifier: tIdentifier,
        otp: tOtp,
      );
      expect(result, equals(const Right<Failure, void>(null)));
      verify(() async {
        await remoteDataSource.confirmSignup(
          identifier: tIdentifier,
          otp: tOtp,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
    test('should return [Left<Failure>] when call  '
        'to remote source is unsuccessful', () async {
      when(() {
        return remoteDataSource.confirmSignup(
          identifier: any<String>(named: 'identifier'),
          otp: any<String>(named: 'otp'),
        );
      }).thenThrow(
        ServerException(
          message: serverFailure.message,
          statusCode: serverFailure.statusCode,
        ),
      );
      final result = await repoImpl.confirmSignup(
        identifier: tIdentifier,
        otp: tOtp,
      );
      expect(result, equals(const Left<Failure, void>(serverFailure)));
      verify(() async {
        await remoteDataSource.confirmSignup(
          identifier: tIdentifier,
          otp: tOtp,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
  });
  group('login', () {
    const tIdentifier = 'Test String';
    const tPassword = 'Test String';
    test('should complete successfully when call  '
        'to remote source is successful', () async {
      when(() {
        return remoteDataSource.login(
          identifier: any<String>(named: 'identifier'),
          password: any<String>(named: 'password'),
        );
      }).thenAnswer((_) async => Future.value());
      final result = await repoImpl.login(
        identifier: tIdentifier,
        password: tPassword,
      );
      expect(result, equals(const Right<Failure, void>(null)));
      verify(() async {
        await remoteDataSource.login(
          identifier: tIdentifier,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
    test('should return [Left<Failure>] when call  '
        'to remote source is unsuccessful', () async {
      when(() {
        return remoteDataSource.login(
          identifier: any<String>(named: 'identifier'),
          password: any<String>(named: 'password'),
        );
      }).thenThrow(
        ServerException(
          message: serverFailure.message,
          statusCode: serverFailure.statusCode,
        ),
      );
      final result = await repoImpl.login(
        identifier: tIdentifier,
        password: tPassword,
      );
      expect(result, equals(const Left<Failure, void>(serverFailure)));
      verify(() async {
        await remoteDataSource.login(
          identifier: tIdentifier,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
  });
  group('signupUser', () {
    final tResult = UserModel.empty();
    const tName = 'Test String';
    const tEmail = 'Test String';
    const tPassword = 'Test String';
    test('should return [Right<User>] when call  '
        'to remote source is successful', () async {
      when(() {
        return remoteDataSource.signupUser(
          name: any<String>(named: 'name'),
          email: any<String>(named: 'email'),
          password: any<String>(named: 'password'),
        );
      }).thenAnswer((_) async => tResult);
      final result = await repoImpl.signupUser(
        name: tName,
        email: tEmail,
        password: tPassword,
      );
      expect(result, equals(Right<Failure, User>(tResult)));
      verify(() async {
        await remoteDataSource.signupUser(
          name: tName,
          email: tEmail,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
    test('should return [Left<Failure>] when call  '
        'to remote source is unsuccessful', () async {
      when(() {
        return remoteDataSource.signupUser(
          name: any<String>(named: 'name'),
          email: any<String>(named: 'email'),
          password: any<String>(named: 'password'),
        );
      }).thenThrow(
        ServerException(
          message: serverFailure.message,
          statusCode: serverFailure.statusCode,
        ),
      );
      final result = await repoImpl.signupUser(
        name: tName,
        email: tEmail,
        password: tPassword,
      );
      expect(result, equals(const Left<Failure, User>(serverFailure)));
      verify(() async {
        await remoteDataSource.signupUser(
          name: tName,
          email: tEmail,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
  });
  group('signup', () {
    final tResult = UserModel.empty();
    const tName = 'Test String';
    const tEmail = 'Test String';
    const tPassword = 'Test String';
    test('should return [Right<User>] when call  '
        'to remote source is successful', () async {
      when(() {
        return remoteDataSource.signup(
          name: any<String>(named: 'name'),
          email: any<String>(named: 'email'),
          password: any<String>(named: 'password'),
        );
      }).thenAnswer((_) async => tResult);
      final result = await repoImpl.signup(
        name: tName,
        email: tEmail,
        password: tPassword,
      );
      expect(result, equals(Right<Failure, User>(tResult)));
      verify(() async {
        await remoteDataSource.signup(
          name: tName,
          email: tEmail,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
    test('should return [Left<Failure>] when call  '
        'to remote source is unsuccessful', () async {
      when(() {
        return remoteDataSource.signup(
          name: any<String>(named: 'name'),
          email: any<String>(named: 'email'),
          password: any<String>(named: 'password'),
        );
      }).thenThrow(
        ServerException(
          message: serverFailure.message,
          statusCode: serverFailure.statusCode,
        ),
      );
      final result = await repoImpl.signup(
        name: tName,
        email: tEmail,
        password: tPassword,
      );
      expect(result, equals(const Left<Failure, User>(serverFailure)));
      verify(() async {
        await remoteDataSource.signup(
          name: tName,
          email: tEmail,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
  });
  group('verifyAuth', () {
    const tResult = true;
    test('should return [Right<bool>] when call  '
        'to remote source is successful', () async {
      when(
        () => remoteDataSource.verifyAuth(),
      ).thenAnswer((_) async => tResult);
      final result = await repoImpl.verifyAuth();
      expect(result, equals(const Right<Failure, bool>(tResult)));
      verify(() async => remoteDataSource.verifyAuth()).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
    test('should return [Left<Failure>] when call  '
        'to remote source is unsuccessful', () async {
      when(() => remoteDataSource.verifyAuth()).thenThrow(
        ServerException(
          message: serverFailure.message,
          statusCode: serverFailure.statusCode,
        ),
      );
      final result = await repoImpl.verifyAuth();
      expect(result, equals(const Left<Failure, bool>(serverFailure)));
      verify(() async => remoteDataSource.verifyAuth()).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
  });
  group('test', () {
    const tPositional = 'Test String';
    const tOptionalPositional = 'Test String';
    test('should complete successfully when call  '
        'to remote source is successful', () async {
      when(() {
        return remoteDataSource.test(
          any<String>(),
          optionalPositional: any<String?>(named: 'optionalPositional'),
        );
      }).thenAnswer((_) async => Future.value());
      final result = await repoImpl.test(
        tPositional,
        optionalPositional: tOptionalPositional,
      );
      expect(result, equals(const Right<Failure, void>(null)));
      verify(() async {
        await remoteDataSource.test(
          tPositional,
          optionalPositional: tOptionalPositional,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
    test('should return [Left<Failure>] when call  '
        'to remote source is unsuccessful', () async {
      when(() {
        return remoteDataSource.test(
          any<String>(),
          optionalPositional: any<String?>(named: 'optionalPositional'),
        );
      }).thenThrow(
        ServerException(
          message: serverFailure.message,
          statusCode: serverFailure.statusCode,
        ),
      );
      final result = await repoImpl.test(
        tPositional,
        optionalPositional: tOptionalPositional,
      );
      expect(result, equals(const Left<Failure, void>(serverFailure)));
      verify(() async {
        await remoteDataSource.test(
          tPositional,
          optionalPositional: tOptionalPositional,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
  });
  group('complex', () {
    const tPositional = 'Test String';
    final tNamed = UserModel.empty();
    const tListNamed = <UserModel>[];
    const tConstListNamed = <String>[];
    final tNamedNullable = UserModel.empty();
    setUp(() {
      registerFallbackValue(tNamed);
      registerFallbackValue(tNamedNullable);
    });
    test('should complete successfully when call  '
        'to remote source is successful', () async {
      when(() {
        return remoteDataSource.complex(
          any<String>(),
          named: any<User>(named: 'named'),
          listNamed: any<List<User>>(named: 'listNamed'),
          constListNamed: any<List<String>>(named: 'constListNamed'),
          namedNullable: any<User?>(named: 'namedNullable'),
        );
      }).thenAnswer((_) async => Future.value());
      final result = await repoImpl.complex(
        tPositional,
        named: tNamed,
        listNamed: tListNamed,
        constListNamed: tConstListNamed,
        namedNullable: tNamedNullable,
      );
      expect(result, equals(const Right<Failure, void>(null)));
      verify(() async {
        await remoteDataSource.complex(
          tPositional,
          named: tNamed,
          listNamed: tListNamed,
          constListNamed: tConstListNamed,
          namedNullable: tNamedNullable,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
    test('should return [Left<Failure>] when call  '
        'to remote source is unsuccessful', () async {
      when(() {
        return remoteDataSource.complex(
          any<String>(),
          named: any<User>(named: 'named'),
          listNamed: any<List<User>>(named: 'listNamed'),
          constListNamed: any<List<String>>(named: 'constListNamed'),
          namedNullable: any<User?>(named: 'namedNullable'),
        );
      }).thenThrow(
        ServerException(
          message: serverFailure.message,
          statusCode: serverFailure.statusCode,
        ),
      );
      final result = await repoImpl.complex(
        tPositional,
        named: tNamed,
        listNamed: tListNamed,
        constListNamed: tConstListNamed,
        namedNullable: tNamedNullable,
      );
      expect(result, equals(const Left<Failure, void>(serverFailure)));
      verify(() async {
        await remoteDataSource.complex(
          tPositional,
          named: tNamed,
          listNamed: tListNamed,
          constListNamed: tConstListNamed,
          namedNullable: tNamedNullable,
        );
      }).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
  });
  group('streamOne', () {
    const tResult = <UserModel>[];
    const tId = 'Test String';
    test('should emit [Right<List<User>>] when  '
        'call to remote source is successful', () {
      when(
        () => remoteDataSource.streamOne(any<String>()),
      ).thenAnswer((_) => Stream.value(tResult));
      final stream = repoImpl.streamOne(tId);
      expect(stream, emits(const Right<Failure, List<User>>(tResult)));
      verify(() => remoteDataSource.streamOne(tId)).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
    test('should emit [Left<Failure>] when call  '
        'to remote source is unsuccessful', () {
      when(() => remoteDataSource.streamOne(any<String>())).thenAnswer((_) {
        return Stream.error(
          ServerException(
            message: serverFailure.message,
            statusCode: serverFailure.statusCode,
          ),
        );
      });
      final stream = repoImpl.streamOne(tId);
      expect(stream, emits(const Left<Failure, List<User>>(serverFailure)));
      verify(() => remoteDataSource.streamOne(tId)).called(1);
      verifyNoMoreInteractions(remoteDataSource);
    });
  });
}

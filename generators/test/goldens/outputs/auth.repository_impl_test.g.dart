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
  group(
    'confirmSignup',
    () {
      const tIdentifier = 'Test String';
      const tOtp = 'Test String';
      test(
        'should complete successfully when call to remote source is successful',
        () async {
          when(() {
            return remoteDataSource.confirmSignup(
              identifier: any(named: 'identifier'),
              otp: any(named: 'otp'),
            );
          }).thenAnswer((_) async => Future.value());
          final result = await repoImpl.confirmSignup(
            identifier: tIdentifier,
            otp: tOtp,
          );
          expect(
            result,
            equals(const Right<Failure, void>(null)),
          );
          verify(() {
            remoteDataSource.confirmSignup(
              identifier: tIdentifier,
              otp: tOtp,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
      test(
        'should return [Left<Failure>] when call to remote source is unsuccessful',
        () async {
          when(() {
            return remoteDataSource.confirmSignup(
              identifier: any(named: 'identifier'),
              otp: any(named: 'otp'),
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
          expect(
            result,
            equals(const Left<Failure, void>(serverFailure)),
          );
          verify(() {
            remoteDataSource.confirmSignup(
              identifier: tIdentifier,
              otp: tOtp,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
    },
  );
  group(
    'login',
    () {
      const tIdentifier = 'Test String';
      const tPassword = 'Test String';
      test(
        'should complete successfully when call to remote source is successful',
        () async {
          when(() {
            return remoteDataSource.login(
              identifier: any(named: 'identifier'),
              password: any(named: 'password'),
            );
          }).thenAnswer((_) async => Future.value());
          final result = await repoImpl.login(
            identifier: tIdentifier,
            password: tPassword,
          );
          expect(
            result,
            equals(const Right<Failure, void>(null)),
          );
          verify(() {
            remoteDataSource.login(
              identifier: tIdentifier,
              password: tPassword,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
      test(
        'should return [Left<Failure>] when call to remote source is unsuccessful',
        () async {
          when(() {
            return remoteDataSource.login(
              identifier: any(named: 'identifier'),
              password: any(named: 'password'),
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
          expect(
            result,
            equals(const Left<Failure, void>(serverFailure)),
          );
          verify(() {
            remoteDataSource.login(
              identifier: tIdentifier,
              password: tPassword,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
    },
  );
  group(
    'signupUser',
    () {
      final tResult = UserModel.empty();
      const tName = 'Test String';
      const tEmail = 'Test String';
      const tPassword = 'Test String';
      test(
        'should return [Right<User>] when call to remote source is successful',
        () async {
          when(() {
            return remoteDataSource.signupUser(
              name: any(named: 'name'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            );
          }).thenAnswer((_) async => tResult);
          final result = await repoImpl.signupUser(
            name: tName,
            email: tEmail,
            password: tPassword,
          );
          expect(
            result,
            equals(Right<Failure, User>(tResult)),
          );
          verify(() {
            remoteDataSource.signupUser(
              name: tName,
              email: tEmail,
              password: tPassword,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
      test(
        'should return [Left<Failure>] when call to remote source is unsuccessful',
        () async {
          when(() {
            return remoteDataSource.signupUser(
              name: any(named: 'name'),
              email: any(named: 'email'),
              password: any(named: 'password'),
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
          expect(
            result,
            equals(const Left<Failure, User>(serverFailure)),
          );
          verify(() {
            remoteDataSource.signupUser(
              name: tName,
              email: tEmail,
              password: tPassword,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
    },
  );
  group(
    'signup',
    () {
      final tResult = UserModel.empty();
      const tName = 'Test String';
      const tEmail = 'Test String';
      const tPassword = 'Test String';
      test(
        'should return [Right<User>] when call to remote source is successful',
        () async {
          when(() {
            return remoteDataSource.signup(
              name: any(named: 'name'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            );
          }).thenAnswer((_) async => tResult);
          final result = await repoImpl.signup(
            name: tName,
            email: tEmail,
            password: tPassword,
          );
          expect(
            result,
            equals(Right<Failure, User>(tResult)),
          );
          verify(() {
            remoteDataSource.signup(
              name: tName,
              email: tEmail,
              password: tPassword,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
      test(
        'should return [Left<Failure>] when call to remote source is unsuccessful',
        () async {
          when(() {
            return remoteDataSource.signup(
              name: any(named: 'name'),
              email: any(named: 'email'),
              password: any(named: 'password'),
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
          expect(
            result,
            equals(const Left<Failure, User>(serverFailure)),
          );
          verify(() {
            remoteDataSource.signup(
              name: tName,
              email: tEmail,
              password: tPassword,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
    },
  );
  group(
    'verifyAuth',
    () {
      const tResult = true;
      test(
        'should return [Right<bool>] when call to remote source is successful',
        () async {
          when(
            () => remoteDataSource.verifyAuth(),
          ).thenAnswer((_) async => tResult);
          final result = await repoImpl.verifyAuth();
          expect(
            result,
            equals(Right<Failure, bool>(tResult)),
          );
          verify(() => remoteDataSource.verifyAuth()).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
      test(
        'should return [Left<Failure>] when call to remote source is unsuccessful',
        () async {
          when(() => remoteDataSource.verifyAuth()).thenThrow(
            ServerException(
              message: serverFailure.message,
              statusCode: serverFailure.statusCode,
            ),
          );
          final result = await repoImpl.verifyAuth();
          expect(
            result,
            equals(const Left<Failure, bool>(serverFailure)),
          );
          verify(() => remoteDataSource.verifyAuth()).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
    },
  );
  group(
    'test',
    () {
      const tPositional = 'Test String';
      const tOptionalPositional = 'Test String';
      test(
        'should complete successfully when call to remote source is successful',
        () async {
          when(
            () => remoteDataSource.test(
              any(),
              any(),
            ),
          ).thenAnswer((_) async => Future.value());
          final result = await repoImpl.test(
            tPositional,
            tOptionalPositional,
          );
          expect(
            result,
            equals(const Right<Failure, void>(null)),
          );
          verify(
            () => remoteDataSource.test(
              tPositional,
              tOptionalPositional,
            ),
          ).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
      test(
        'should return [Left<Failure>] when call to remote source is unsuccessful',
        () async {
          when(
            () => remoteDataSource.test(
              any(),
              any(),
            ),
          ).thenThrow(
            ServerException(
              message: serverFailure.message,
              statusCode: serverFailure.statusCode,
            ),
          );
          final result = await repoImpl.test(
            tPositional,
            tOptionalPositional,
          );
          expect(
            result,
            equals(const Left<Failure, void>(serverFailure)),
          );
          verify(
            () => remoteDataSource.test(
              tPositional,
              tOptionalPositional,
            ),
          ).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
    },
  );
  group(
    'complex',
    () {
      const tPositional = 'Test String';
      final tNamedNullable = UserModel.empty();
      final tNamed = UserModel.empty();
      const tListNamed = <User>[];
      const tConstListNamed = <String>[];
      setUp(() {
        registerFallbackValue(tNamedNullable);
        registerFallbackValue(tNamed);
      });
      test(
        'should complete successfully when call to remote source is successful',
        () async {
          when(() {
            return remoteDataSource.complex(
              any(),
              namedNullable: any(named: 'namedNullable'),
              named: any(named: 'named'),
              listNamed: any(named: 'listNamed'),
              constListNamed: any(named: 'constListNamed'),
            );
          }).thenAnswer((_) async => Future.value());
          final result = await repoImpl.complex(
            tPositional,
            namedNullable: tNamedNullable,
            named: tNamed,
            listNamed: tListNamed,
            constListNamed: tConstListNamed,
          );
          expect(
            result,
            equals(const Right<Failure, void>(null)),
          );
          verify(() {
            remoteDataSource.complex(
              tPositional,
              namedNullable: tNamedNullable,
              named: tNamed,
              listNamed: tListNamed,
              constListNamed: tConstListNamed,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
      test(
        'should return [Left<Failure>] when call to remote source is unsuccessful',
        () async {
          when(() {
            return remoteDataSource.complex(
              any(),
              namedNullable: any(named: 'namedNullable'),
              named: any(named: 'named'),
              listNamed: any(named: 'listNamed'),
              constListNamed: any(named: 'constListNamed'),
            );
          }).thenThrow(
            ServerException(
              message: serverFailure.message,
              statusCode: serverFailure.statusCode,
            ),
          );
          final result = await repoImpl.complex(
            tPositional,
            namedNullable: tNamedNullable,
            named: tNamed,
            listNamed: tListNamed,
            constListNamed: tConstListNamed,
          );
          expect(
            result,
            equals(const Left<Failure, void>(serverFailure)),
          );
          verify(() {
            remoteDataSource.complex(
              tPositional,
              namedNullable: tNamedNullable,
              named: tNamed,
              listNamed: tListNamed,
              constListNamed: tConstListNamed,
            );
          }).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
    },
  );
  group(
    'streamOne',
    () {
      const tResult = <User>[];
      const tId = 'Test String';
      test(
        'should emit [Right<List<User>>] when call to remote source is successful',
        () {
          when(
            () => remoteDataSource.streamOne(any()),
          ).thenAnswer((_) => Stream.value(tResult));
          final stream = repoImpl.streamOne(tId);
          expect(
            stream,
            emits(Right<Failure, List<User>>(tResult)),
          );
          verify(() => remoteDataSource.streamOne(tId)).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
      test(
        'should emit [Left<Failure>] when call to remote source is unsuccessful',
        () {
          when(() => remoteDataSource.streamOne(any())).thenAnswer((_) {
            return Stream.error(
              ServerException(
                message: serverFailure.message,
                statusCode: serverFailure.statusCode,
              ),
            );
          });
          final stream = repoImpl.streamOne(tId);
          expect(
            stream,
            emits(const Left<Failure, List<User>>(serverFailure)),
          );
          verify(() => remoteDataSource.streamOne(tId)).called(1);
          verifyNoMoreInteractions(remoteDataSource);
        },
      );
    },
  );
}

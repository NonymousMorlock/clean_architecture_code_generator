class MockAuthRepo extends Mock implements AuthRepo {}

void main() {
  late AuthRepo repo;
  late ConfirmSignup usecase;
  const tIdentifier = 'Test String';
  const tOtp = 'Test String';
  setUp(() {
    repo = MockAuthRepo();
    usecase = ConfirmSignup(repo);
  });
  test(
    'should call the [AuthRepo.confirmSignup]',
    () async {
      when(() {
        return repo.confirmSignup(
          identifier: any(named: 'identifier'),
          otp: any(named: 'otp'),
        );
      }).thenAnswer((_) async => const Right(null));
      final result = await usecase(
        ConfirmSignupParams(
          identifier: tIdentifier,
          otp: tOtp,
        ),
      );
      expect(
        result,
        equals(const Right<dynamic, void>(null)),
      );
      verify(() {
        repo.confirmSignup(
          identifier: tIdentifier,
          otp: tOtp,
        );
      }).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

void main() {
  late AuthRepo repo;
  late Login usecase;
  const tIdentifier = 'Test String';
  const tPassword = 'Test String';
  setUp(() {
    repo = MockAuthRepo();
    usecase = Login(repo);
  });
  test(
    'should call the [AuthRepo.login]',
    () async {
      when(() {
        return repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        );
      }).thenAnswer((_) async => const Right(null));
      final result = await usecase(
        LoginParams(
          identifier: tIdentifier,
          password: tPassword,
        ),
      );
      expect(
        result,
        equals(const Right<dynamic, void>(null)),
      );
      verify(() {
        repo.login(
          identifier: tIdentifier,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

void main() {
  late AuthRepo repo;
  late SignupUser usecase;
  const tName = 'Test String';
  const tEmail = 'Test String';
  const tPassword = 'Test String';
  final tResult = User.empty();
  setUp(() {
    repo = MockAuthRepo();
    usecase = SignupUser(repo);
  });
  test(
    'should call the [AuthRepo.signupUser]',
    () async {
      when(() {
        return repo.signupUser(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        );
      }).thenAnswer((_) async => Right(tResult));
      final result = await usecase(
        SignupUserParams(
          name: tName,
          email: tEmail,
          password: tPassword,
        ),
      );
      expect(
        result,
        equals(Right<dynamic, User>(tResult)),
      );
      verify(() {
        repo.signupUser(
          name: tName,
          email: tEmail,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

void main() {
  late AuthRepo repo;
  late Signup usecase;
  const tName = 'Test String';
  const tEmail = 'Test String';
  const tPassword = 'Test String';
  final tResult = User.empty();
  setUp(() {
    repo = MockAuthRepo();
    usecase = Signup(repo);
  });
  test(
    'should call the [AuthRepo.signup]',
    () async {
      when(() {
        return repo.signup(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        );
      }).thenAnswer((_) async => Right(tResult));
      final result = await usecase(
        SignupParams(
          name: tName,
          email: tEmail,
          password: tPassword,
        ),
      );
      expect(
        result,
        equals(Right<dynamic, User>(tResult)),
      );
      verify(() {
        repo.signup(
          name: tName,
          email: tEmail,
          password: tPassword,
        );
      }).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

void main() {
  late AuthRepo repo;
  late VerifyAuth usecase;
  const tResult = true;
  setUp(() {
    repo = MockAuthRepo();
    usecase = VerifyAuth(repo);
  });
  test(
    'should call the [AuthRepo.verifyAuth]',
    () async {
      when(
        () => repo.verifyAuth(),
      ).thenAnswer((_) async => const Right(tResult));
      final result = await usecase();
      expect(
        result,
        equals(const Right<dynamic, bool>(tResult)),
      );
      verify(() => repo.verifyAuth()).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

void main() {
  late AuthRepo repo;
  late Test usecase;
  const tPositional = 'Test String';
  const tOptionalPositional = 'Test String';
  setUp(() {
    repo = MockAuthRepo();
    usecase = Test(repo);
  });
  test(
    'should call the [AuthRepo.test]',
    () async {
      when(
        () => repo.test(
          any(),
          any(),
        ),
      ).thenAnswer((_) async => const Right(null));
      final result = await usecase(
        TestParams(
          positional: tPositional,
          optionalPositional: tOptionalPositional,
        ),
      );
      expect(
        result,
        equals(const Right<dynamic, void>(null)),
      );
      verify(
        () => repo.test(
          tPositional,
          tOptionalPositional,
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

void main() {
  late AuthRepo repo;
  late Complex usecase;
  const tPositional = 'Test String';
  final tNamedNullable = User.empty();
  final tNamed = User.empty();
  const tListNamed = <User>[];
  const tConstListNamed = <String>[];
  setUp(() {
    repo = MockAuthRepo();
    usecase = Complex(repo);
    registerFallbackValue(tNamedNullable);
    registerFallbackValue(tNamed);
  });
  test(
    'should call the [AuthRepo.complex]',
    () async {
      when(() {
        return repo.complex(
          any(),
          namedNullable: any(named: 'namedNullable'),
          named: any(named: 'named'),
          listNamed: any(named: 'listNamed'),
          constListNamed: any(named: 'constListNamed'),
        );
      }).thenAnswer((_) async => const Right(null));
      final result = await usecase(
        ComplexParams(
          positional: tPositional,
          namedNullable: tNamedNullable,
          named: tNamed,
          listNamed: tListNamed,
          constListNamed: tConstListNamed,
        ),
      );
      expect(
        result,
        equals(const Right<dynamic, void>(null)),
      );
      verify(() {
        repo.complex(
          tPositional,
          namedNullable: tNamedNullable,
          named: tNamed,
          listNamed: tListNamed,
          constListNamed: tConstListNamed,
        );
      }).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

void main() {
  late AuthRepo repo;
  late StreamOne usecase;
  const tId = 'Test String';
  const tResult = <User>[];
  setUp(() {
    repo = MockAuthRepo();
    usecase = StreamOne(repo);
  });
  test(
    'should call the [AuthRepo.streamOne]',
    () {
      when(
        () => repo.streamOne(any()),
      ).thenAnswer((_) => Stream.value(const Right(tResult)));
      final stream = usecase(tId);
      expect(
        stream,
        emits(const Right<dynamic, List<User>>(tResult)),
      );
      verify(() => repo.streamOne(tId)).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

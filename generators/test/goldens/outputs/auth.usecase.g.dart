class ConfirmSignup implements UsecaseWithParams<void, ConfirmSignupParams> {
  const ConfirmSignup(this._repo);
  final AuthRepo _repo;
  @override
  ResultFuture<void> call(ConfirmSignupParams params) {
    return _repo.confirmSignup(
      identifier: params.identifier,
      otp: params.otp,
    );
  }
}

class ConfirmSignupParams extends Equatable {
  const ConfirmSignupParams({
    required this.identifier,
    required this.otp,
  });
  const ConfirmSignupParams.empty()
    : this(
        identifier: 'Test String',
        otp: 'Test String',
      );
  final String identifier;
  final String otp;
  @override
  List<Object?> get props => [
    identifier,
    otp,
  ];
}

class Login implements UsecaseWithParams<void, LoginParams> {
  const Login(this._repo);
  final AuthRepo _repo;
  @override
  ResultFuture<void> call(LoginParams params) {
    return _repo.login(
      identifier: params.identifier,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  const LoginParams({
    required this.identifier,
    required this.password,
  });
  const LoginParams.empty()
    : this(
        identifier: 'Test String',
        password: 'Test String',
      );
  final String identifier;
  final String password;
  @override
  List<Object?> get props => [
    identifier,
    password,
  ];
}

class SignupUser implements UsecaseWithParams<User, SignupUserParams> {
  const SignupUser(this._repo);
  final AuthRepo _repo;
  @override
  ResultFuture<User> call(SignupUserParams params) {
    return _repo.signupUser(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}

class SignupUserParams extends Equatable {
  const SignupUserParams({
    required this.name,
    required this.email,
    required this.password,
  });
  const SignupUserParams.empty()
    : this(
        name: 'Test String',
        email: 'Test String',
        password: 'Test String',
      );
  final String name;
  final String email;
  final String password;
  @override
  List<Object?> get props => [
    name,
    email,
    password,
  ];
}

class Signup implements UsecaseWithParams<User, SignupParams> {
  const Signup(this._repo);
  final AuthRepo _repo;
  @override
  ResultFuture<User> call(SignupParams params) {
    return _repo.signup(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}

class SignupParams extends Equatable {
  const SignupParams({
    required this.name,
    required this.email,
    required this.password,
  });
  const SignupParams.empty()
    : this(
        name: 'Test String',
        email: 'Test String',
        password: 'Test String',
      );
  final String name;
  final String email;
  final String password;
  @override
  List<Object?> get props => [
    name,
    email,
    password,
  ];
}

class VerifyAuth implements UsecaseWithoutParams<bool> {
  const VerifyAuth(this._repo);
  final AuthRepo _repo;
  @override
  ResultFuture<bool> call() {
    return _repo.verifyAuth();
  }
}

class VerifyAuthParams extends Equatable {
  const VerifyAuthParams();
  const VerifyAuthParams.empty() : this();
  @override
  List<Object?> get props => [];
}

class Test implements UsecaseWithParams<void, TestParams> {
  const Test(this._repo);
  final AuthRepo _repo;
  @override
  ResultFuture<void> call(TestParams params) {
    return _repo.test(
      params.positional,
      params.optionalPositional,
    );
  }
}

class TestParams extends Equatable {
  const TestParams({
    required this.positional,
    required this.optionalPositional,
  });
  const TestParams.empty()
    : this(
        positional: 'Test String',
        optionalPositional: 'Test String',
      );
  final String positional;
  final String optionalPositional;
  @override
  List<Object?> get props => [
    positional,
    optionalPositional,
  ];
}

class Complex implements UsecaseWithParams<void, ComplexParams> {
  const Complex(this._repo);
  final AuthRepo _repo;
  @override
  ResultFuture<void> call(ComplexParams params) {
    return _repo.complex(
      params.positional,
      namedNullable: params.namedNullable,
      named: params.named,
      listNamed: params.listNamed,
      constListNamed: params.constListNamed,
    );
  }
}

class ComplexParams extends Equatable {
  const ComplexParams({
    required this.positional,
    required this.namedNullable,
    required this.named,
    required this.listNamed,
    required this.constListNamed,
  });
  ComplexParams.empty()
    : this(
        positional: 'Test String',
        namedNullable: null,
        named: User.empty(),
        listNamed: const [],
        constListNamed: const [],
      );
  final String positional;
  final User namedNullable;
  final User named;
  final List<User> listNamed;
  final List<String> constListNamed;
  @override
  List<Object?> get props => [
    positional,
    namedNullable,
    named,
    listNamed,
    constListNamed,
  ];
}

class StreamOne implements StreamUsecaseWithParams<List<User>, String> {
  const StreamOne(this._repo);
  final AuthRepo _repo;
  @override
  ResultStream<List<User>> call(String params) {
    return _repo.streamOne(params);
  }
}

class StreamOneParams extends Equatable {
  const StreamOneParams({required this.id});
  const StreamOneParams.empty() : this(id: 'Test String');
  final String id;
  @override
  List<Object?> get props => [id];
}

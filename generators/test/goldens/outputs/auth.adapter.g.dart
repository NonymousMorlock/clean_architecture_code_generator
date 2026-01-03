class AuthAdapter extends Cubit<AuthState> {
  AuthAdapter({
    required ConfirmSignup confirmSignup,
    required Login login,
    required SignupUser signupUser,
    required Signup signup,
    required VerifyAuth verifyAuth,
    required Test test,
    required Complex complex,
    required StreamOne streamOne,
  }) : _confirmSignup = confirmSignup,
       _login = login,
       _signupUser = signupUser,
       _signup = signup,
       _verifyAuth = verifyAuth,
       _test = test,
       _complex = complex,
       _streamOne = streamOne,
       super(const AuthInitial());
  final ConfirmSignup _confirmSignup;
  final Login _login;
  final SignupUser _signupUser;
  final Signup _signup;
  final VerifyAuth _verifyAuth;
  final Test _test;
  final Complex _complex;
  final StreamOne _streamOne;
  StreamSubscription<List<User>>? _streamOneSubscription;
  Future<void> confirmSignup({
    required String identifier,
    required String otp,
  }) async {
    emit(const AuthLoading());
    final result = await _confirmSignup(
      ConfirmSignupParams(identifier: identifier, otp: otp),
    );
    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (_) => emit(const SignupConfirmed()),
    );
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _login(
      LoginParams(identifier: identifier, password: password),
    );
    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (_) => emit(const LoggedIn()),
    );
  }

  Future<void> signupUser({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _signupUser(
      SignupUserParams(name: name, email: email, password: password),
    );
    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (user) => emit(UserSignedUp(user: user)),
    );
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _signup(
      SignupParams(name: name, email: email, password: password),
    );
    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (user) => emit(SignedUp(user: user)),
    );
  }

  Future<void> verifyAuth() async {
    emit(const AuthLoading());
    final result = await _verifyAuth();
    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (data) => emit(AuthVerified(data: data)),
    );
  }

  Future<void> test({
    required String positional,
    String? optionalPositional,
  }) async {
    emit(const AuthLoading());
    final result = await _test(
      TestParams(
        positional: positional,
        optionalPositional: optionalPositional,
      ),
    );
    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (_) => emit(const AuthTested()),
    );
  }

  Future<void> complex({
    required String positional,
    required User named,
    required List<User> listNamed,
    required List<String> constListNamed,
    User? namedNullable,
  }) async {
    emit(const AuthLoading());
    final result = await _complex(
      ComplexParams(
        positional: positional,
        named: named,
        listNamed: listNamed,
        constListNamed: constListNamed,
        namedNullable: namedNullable,
      ),
    );
    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (_) => emit(const AuthComplexed()),
    );
  }

  Future<void> streamOneStream({required String id}) async {
    await _streamOneSubscription?.cancel();
    final stream = _streamOne(id);
    _streamOneSubscription = stream.listen(
      (result) {
        result.fold(
          (failure) => emit(AuthError.fromFailure(failure)),
          (userList) => emit(OnesStreamed(userList: userList)),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(
          const AuthError(
            message: 'Something went wrong',
            title: 'Unknown Error',
          ),
        );
      },
      cancelOnError: false,
    );
  }

  @override
  void emit(AuthState state) {
    if (isClosed) return;
    super.emit(state);
  }

  @override
  Future<void> close() async {
    await _streamOneSubscription?.cancel();
    return super.close();
  }
}

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class SignupConfirmed extends AuthState {
  const SignupConfirmed();
}

final class LoggedIn extends AuthState {
  const LoggedIn();
}

final class UserSignedUp extends AuthState {
  const UserSignedUp({required this.user});
  final User user;
  @override
  List<Object?> get props => [user];
}

final class SignedUp extends AuthState {
  const SignedUp({required this.user});
  final User user;
  @override
  List<Object?> get props => [user];
}

final class AuthVerified extends AuthState {
  const AuthVerified({required this.data});
  final bool data;
  @override
  List<Object?> get props => [data];
}

final class AuthTested extends AuthState {
  const AuthTested();
}

final class AuthComplexed extends AuthState {
  const AuthComplexed();
}

final class OnesStreamed extends AuthState {
  const OnesStreamed({required this.userList});
  final List<User> userList;
  @override
  List<Object?> get props => userList;
}

final class AuthError extends AuthState {
  const AuthError({required this.message, required this.title});
  AuthError.fromFailure(Failure failure)
    : this(
        message: failure.message,
        title:
            '${failure.statusCode is int ? 'Error ' : ''}${failure.statusCode}',
      );
  final String message;
  final String? title;
  @override
  List<Object?> get props => [message, title];
}

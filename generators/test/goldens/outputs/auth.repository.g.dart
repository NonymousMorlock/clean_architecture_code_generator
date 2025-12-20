abstract interface class AuthRepo {
  const AuthRepo();
  ResultFuture<void> confirmSignup({
    required String identifier,
    required String otp,
  });
  ResultFuture<void> login({
    required String identifier,
    required String password,
  });
  ResultFuture<User> signupUser({
    required String name,
    required String email,
    required String password,
  });
  ResultFuture<User> signup({
    required String name,
    required String email,
    required String password,
  });
  ResultFuture<bool> verifyAuth();
  ResultFuture<void> test(
    String positional, [
    String optionalPositional,
  ]);
  ResultFuture<void> complex(
    String positional, {
    User namedNullable,
    required User named,
    required List<User> listNamed,
    required List<String> constListNamed,
  });
  ResultStream<List<User>> streamOne(String id);
}

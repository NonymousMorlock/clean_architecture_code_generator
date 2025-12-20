import 'package:annotations/annotations.dart';

part 'auth_repository_tbg.g.dart';

typedef ResultFuture<T> = Future<T>;
typedef ResultStream<T> = Stream<T>;

@repoGen
@usecaseGen
@repoImplGen
@remoteSrcGen
@adapterGen
@usecaseTestGen
@repoImplTestGen
@remoteSrcTestGen
class AuthRepoTBG {
  external ResultFuture<void> confirmSignup({
    required String identifier,
    required String otp,
  });

  external ResultFuture<void> login({
    required String identifier,
    required String password,
  });

  external ResultFuture<User> signupUser({
    required String name,
    required String email,
    required String password,
  });

  external ResultFuture<User> signup({
    required String name,
    required String email,
    required String password,
  });

  external ResultFuture<bool> verifyAuth();

  external ResultFuture<void> test(
    String positional, [
    String optionalPositional,
  ]);

  external ResultFuture<void> complex(
    String positional, {
    required User named,
    required List<User> listNamed,
    required List<String> constListNamed,
    User? namedNullable,
  });

  external ResultStream<List<User>> streamOne(String id);
}

class User {}

abstract interface class AuthRemoteDataSource {
  const AuthRemoteDataSource();
  Future<void> confirmSignup({required String identifier, required String otp});
  Future<void> login({required String identifier, required String password});
  Future<UserModel> signupUser({
    required String name,
    required String email,
    required String password,
  });
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  });
  Future<bool> verifyAuth();
  Future<void> test(String positional, {String? optionalPositional});
  Future<void> complex(
    String positional, {
    required User named,
    required List<User> listNamed,
    required List<String> constListNamed,
    User? namedNullable,
  });
  Stream<List<UserModel>> streamOne(String id);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({required Dio dio}) : _dio = dio;
  final Dio _dio;
  @override
  Future<void> confirmSignup({
    required String identifier,
    required String otp,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> signupUser({
    required String name,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyAuth() async {
    throw UnimplementedError();
  }

  @override
  Future<void> test(String positional, {String? optionalPositional}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> complex(
    String positional, {
    required User named,
    required List<User> listNamed,
    required List<String> constListNamed,
    User? namedNullable,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<UserModel>> streamOne(String id) {
    throw UnimplementedError();
  }
}

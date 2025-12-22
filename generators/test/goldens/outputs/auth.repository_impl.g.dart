class AuthRepoImpl implements AuthRepo {
  const AuthRepoImpl(this._remoteDataSource);
  final AuthRemoteDataSource _remoteDataSource;
  @override
  ResultFuture<void> confirmSignup({
    required String identifier,
    required String otp,
  }) async {
    try {
      await _remoteDataSource.confirmSignup(identifier: identifier, otp: otp);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> login({
    required String identifier,
    required String password,
  }) async {
    try {
      await _remoteDataSource.login(identifier: identifier, password: password);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<User> signupUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.signupUser(
        name: name,
        email: email,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<User> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.signup(
        name: name,
        email: email,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> verifyAuth() async {
    try {
      final result = await _remoteDataSource.verifyAuth();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> test(
    String positional, {
    String? optionalPositional,
  }) async {
    try {
      await _remoteDataSource.test(
        positional,
        optionalPositional: optionalPositional,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> complex(
    String positional, {
    required User named,
    required List<User> listNamed,
    required List<String> constListNamed,
    User? namedNullable,
  }) async {
    try {
      await _remoteDataSource.complex(
        positional,
        named: named,
        listNamed: listNamed,
        constListNamed: constListNamed,
        namedNullable: namedNullable,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultStream<List<User>> streamOne(String id) {
    return _remoteDataSource
        .streamOne(id)
        .transform(
          StreamTransformer<List<UserModel>, List<User>>.fromHandlers(
            handleData: (data, sink) {
              sink.add(Right(data));
            },
            handleError: (error, stackTrace, sink) {
              if (error is ServerException) {
                sink.add(
                  Left(
                    ServerFailure(
                      message: error.message,
                      statusCode: error.statusCode,
                    ),
                  ),
                );
              } else {
                sink.add(
                  const Left(
                    ServerFailure(
                      message: 'Something went wrong',
                      statusCode: 500,
                    ),
                  ),
                );
              }
            },
          ),
        );
  }
}

import 'dart:async';

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:example/repo_gen.dart';
import 'package:example/typedefs.dart';
import 'package:flutter/widgets.dart';
import 'package:example/usecase.dart';

part 'repo_gen.g.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;

@repoGen
@usecaseGen
@usecaseTestGen
@repoImplGen
@remoteSrcGen
class AuthRepoTBG {
  external ResultFuture<void> register({
    required String name,
    required String password,
    required String email,
    required String phone,
  });

  external ResultFuture<User> login({
    required String email,
    required String password,
  });

  external ResultFuture<void> forgotPassword(String email);

  external ResultFuture<void> verifyOTP({
    required String email,
    required String otp,
  });

  external ResultFuture<void> resetPassword({
    required String email,
    required String newPassword,
  });

  external ResultFuture<bool> verifyToken();

  external ResultFuture<List<Milestone>> getAddresses();
  external ResultFuture<List<String>> getData();
}

class User {}

class Milestone {}

class Client {}

class Project {}

class Material {}

class ExamQuestion {}

class UserExam {}

class Exam {}

class Either<T, R> {}

class Failure {}

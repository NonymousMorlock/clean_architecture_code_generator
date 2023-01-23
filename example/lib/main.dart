import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:example/person.dart';
import 'package:flutter/widgets.dart';
import 'package:example/usecase.dart';

part 'main.g.dart';

typedef FunctionalFuture<T> = Future<Either<Failure, T>>;

// @usecaseTestGen
// @usecaseGen
// @repoImplGen
// @remoteSrcGen
@repoGen
class CreditorRepoTBG {
  external Future<Either<Failure, void>> addCreditor({
    required Creditor creditor,
    required String token,
  });

  external Future<Either<Failure, List<Creditor>>> getCreditors(
    int branchId,
    String token,
  );
}

class Creditor {
}

class Tank {}

class Either<T, R> {}

class Failure {}

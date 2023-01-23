import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:example/person.dart';
import 'package:flutter/widgets.dart';
import 'package:example/usecase.dart';

part 'main.g.dart';

typedef FunctionalFuture<T> = Future<Either<Failure, T>>;

@usecaseTestGen
@usecaseGen
@repoImplGen
@remoteSrcGen
@repoGen
class TankRepoTBG {
  external Future<Either<Failure, List<Tank>>> getTanks({
    required int branchId,
    required String token,
  });

  external Future<Either<Failure, void>> addTank({required Tank tank, required
  String token});

}

class Tank {}

class Either<T, R> {}

class Failure {}

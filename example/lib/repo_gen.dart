import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:example/repo_gen.dart';
import 'package:flutter/widgets.dart';
import 'package:example/usecase.dart';

part 'repo_gen.g.dart';

typedef FunctionalFuture<T> = Future<Either<Failure, T>>;

@repoGen
@usecaseGen
@usecaseTestGen
@repoImplGen
@remoteSrcGen
class BranchesRepoTBG {
  external Future<Either<Failure, void>> deleteTank({
    required int tankId,
    required String token,
  });

  external Future<Either<Failure, void>> deleteBranch({
    int branchId,
    String token,
  });

  external Future<Either<Failure, void>> closeBranch({
    int branchId,
    String token,
  });

  external Future<Either<Failure, void>> openBranch({
    int branchId,
    String token,
  });
}

class Either<T, R> {}

class Failure {}

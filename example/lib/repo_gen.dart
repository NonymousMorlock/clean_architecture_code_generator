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
class MaterialRepoTBG {
  // external Future<Either<Failure, List<UserExam>>> getUserExams();

  external Future<Either<Failure, List<Material>>> getMaterials(
    String courseId,
  );

  external Future<Either<Failure, void>> addMaterial(Material material);
}

class Material {}

class ExamQuestion {}

class UserExam {}

class Exam {}

class Either<T, R> {}

class Failure {}

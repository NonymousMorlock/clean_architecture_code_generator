import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:example/repo_gen.dart';
import 'package:flutter/widgets.dart';
import 'package:example/usecase.dart';

part 'repo_gen.g.dart';

typedef FunctionalFuture<T> = Future<Either<Failure, T>>;

// @repoGen
// @usecaseGen
// @usecaseTestGen
// @repoImplGen
// @remoteSrcGen
class ExamRepoTBG {
  external Future<Either<Failure, List<Exam>>> getExams(String
  courseId);

  external Future<Either<Failure, void>> uploadExam(Exam exam);

  external Future<Either<Failure, void>> deleteExam(String examId);

  external Future<Either<Failure, void>> updateExam(Exam exam);
  external Future<Either<Failure, void>> submitExam(UserExam exam);
}

class UserExam {
}

class Exam {
}

class Either<T, R> {}

class Failure {}

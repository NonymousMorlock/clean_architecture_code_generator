import 'dart:async';

import 'package:annotations/annotations.dart';
import 'package:example/model_gen.dart';

part 'repo_gen.g.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;

enum Order { asc, desc }

// @repoGen
// @usecaseGen
// @usecaseTestGen
@repoImplTestGen
// @repoImplGen
// @remoteSrcGen
class CourseRepresentativeRepoTBG {
  external ResultFuture<List<Faculty>> getFaculties();

  external ResultFuture<List<Course>> getCourses(String facultyId);

  external ResultFuture<List<Level>> getLevels({
    required String facultyId,
    required String courseId,
  });
}

class Level {}

class Wallet {}

class Transaction {}

class OrderStatus {}

class CartProduct {}

class WishlistProduct {}

class Subscription {}

class BillingDetails {}

class Category {}

class Review {}

class Product {}

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

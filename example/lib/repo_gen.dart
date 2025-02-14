import 'dart:async';

import 'package:annotations/annotations.dart';

part 'repo_gen.g.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;

enum Order { asc, desc }

@repoGen
@usecaseGen
// @usecaseTestGen
// @repoImplTestGen
@repoImplGen
@remoteSrcGen
class BlockRepoTBG {
  external ResultFuture<Feedback> leaveFeedback(Feedback feedback);
}

class Feedback {}

class Booking {}

class Room {}

class Block {}

class ProductCategory {}

class CourseRepresentative {}

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

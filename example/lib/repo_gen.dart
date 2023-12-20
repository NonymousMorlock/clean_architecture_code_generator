import 'dart:async';

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:example/usecase.dart';


part 'repo_gen.g.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;

@repoGen
@usecaseGen
@usecaseTestGen
@repoImplGen
@remoteSrcGen
class SubscriptionRepoTBG {
  external ResultFuture<String> createPaymentIntent({
    required BillingDetails billingDetails,
    required Subscription subscription,
  });

  external ResultFuture<void> confirmPaymentIntent(String clientSecret);
}

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

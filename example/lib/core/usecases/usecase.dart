// I need these abstractions to define use cases. They cannot be functions.
// ignore_for_file: one_member_abstracts

import 'package:itube/core/typedefs.dart';

abstract class UsecaseWithParams<ReturnType, Params> {
  const UsecaseWithParams();

  ResultFuture<ReturnType> call(Params params);
}

abstract class UsecaseWithoutParams<ReturnType> {
  const UsecaseWithoutParams();

  ResultFuture<ReturnType> call();
}

abstract class StreamUsecaseWithParams<ReturnType, Params> {
  const StreamUsecaseWithParams();

  ResultStream<ReturnType> call(Params params);
}

abstract class StreamUsecaseWithoutParams<ReturnType> {
  const StreamUsecaseWithoutParams();

  ResultStream<ReturnType> call();
}

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
class MeterReportRepoTBG {
  external Future<Either<Failure, List<MeterReport>>> getMeterReports({
    required String date,
    required int branchId,
    required String token,
  });

  external Future<Either<Failure, void>> submitMeterReports({
    required List<MeterReport> meterReports,
    required String token,
  });
}

class MeterReport {}

class DailyProgress {}

class Either<T, R> {}

class Failure {}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo_gen.dart';

// **************************************************************************
// RemoteDataSrcGenerator
// **************************************************************************

abstract class MeterrtRemoteDataSrc {
  Future<List<MeterReport>> getMeterReports({
    required String date,
    required int branchId,
    required String token,
  });

  Future<void> submitMeterReports({
    required List<MeterReport> meterReports,
    required String token,
  });
}

class MeterrtRemoteDataSrcImpl implements MeterrtRemoteDataSrc {
  const MeterrtRemoteDataSrcImpl(this._client);

  final http.Client _client;

  @override
  Future<List<MeterReport>> getMeterReports({
    required String date,
    required int branchId,
    required String token,
  }) async {
    // TODO(getMeterReports): implement getMeterReports
    throw UnimplementedError();
  }

  @override
  Future<void> submitMeterReports({
    required List<MeterReport> meterReports,
    required String token,
  }) async {
    // TODO(submitMeterReports): implement submitMeterReports
    throw UnimplementedError();
  }
}

// **************************************************************************
// RepoGenerator
// **************************************************************************

abstract class MeterReportRepo {
  FunctionalFuture<List<MeterReport>> getMeterReports({
    required String date,
    required int branchId,
    required String token,
  });
  FunctionalFuture<void> submitMeterReports({
    required List<MeterReport> meterReports,
    required String token,
  });
}

// **************************************************************************
// RepoImplGenerator
// **************************************************************************

class MeterReportRepoImpl implements MeterReportRepo {
  const MeterReportRepoImpl(this._remoteDataSource);

  final MeterrtRemoteDataSrc _remoteDataSource;

  @override
  FunctionalFuture<List<MeterReport>> getMeterReports({
    required String date,
    required int branchId,
    required String token,
  }) async {
    try {
      final result = await _remoteDataSource.getMeterReports(
          date: date, branchId: branchId, token: token);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  FunctionalFuture<void> submitMeterReports({
    required List<MeterReport> meterReports,
    required String token,
  }) async {
    try {
      await _remoteDataSource.submitMeterReports(
          meterReports: meterReports, token: token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

// **************************************************************************
// UsecaseGenerator
// **************************************************************************

class GetMeterReports
    extends UsecaseWithParams<List<MeterReport>, GetMeterReportsParams> {
  const GetMeterReports(this._repo);

  final MeterReportRepo _repo;

  @override
  FunctionalFuture<List<MeterReport>> call(GetMeterReportsParams params) =>
      _repo.getMeterReports(
        date: params.date,
        branchId: params.branchId,
        token: params.token,
      );
}

class GetMeterReportsParams extends Equatable {
  const GetMeterReportsParams({
    required this.date,
    required this.branchId,
    required this.token,
  });

  final String date;
  final int branchId;
  final String token;

  @override
  List<dynamic> get props => [
        date,
        branchId,
        token,
      ];
}

class SubmitMeterReports
    extends UsecaseWithParams<void, SubmitMeterReportsParams> {
  const SubmitMeterReports(this._repo);

  final MeterReportRepo _repo;

  @override
  FunctionalFuture<void> call(SubmitMeterReportsParams params) =>
      _repo.submitMeterReports(
        meterReports: params.meterReports,
        token: params.token,
      );
}

class SubmitMeterReportsParams extends Equatable {
  const SubmitMeterReportsParams({
    required this.meterReports,
    required this.token,
  });

  final List<MeterReport> meterReports;
  final String token;

  @override
  List<dynamic> get props => [
        meterReports,
        token,
      ];
}

// **************************************************************************
// UsecaseTestGenerator
// **************************************************************************

class MockMeterReportRepo extends Mock implements MeterReportRepo {}

void main() {
  late MockMeterReportRepo repo;
  late GetMeterReports usecase;

  const tDate = 'Test String';

  const tBranchId = 1;

  const tToken = 'Test String';

  setUp(() {
    repo = MockMeterReportRepo();
    usecase = GetMeterReports(repo);
    registerFallbackValue(tDate);
    registerFallbackValue(tBranchId);
    registerFallbackValue(tToken);
  });

  test(
    'should return [List<MeterReport>] from the repo',
    () async {
      when(
        () => repo.getMeterReports(
          date: any(named: "date"),
          branchId: any(named: "branchId"),
          token: any(named: "token"),
        ),
      ).thenAnswer(
        (_) async => const Right([]),
      );

      final result = await usecase(
        const GetMeterReportsParams(
          date: tDate,
          branchId: tBranchId,
          token: tToken,
        ),
      );
      expect(result, equals(const Right<dynamic, List<MeterReport>>([])));
      verify(
        () => repo.getMeterReports(
          date: any(named: "date"),
          branchId: any(named: "branchId"),
          token: any(named: "token"),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

class MockMeterReportRepo extends Mock implements MeterReportRepo {}

void main() {
  late MockMeterReportRepo repo;
  late SubmitMeterReports usecase;

  const tMeterReports = [];

  const tToken = 'Test String';

  setUp(() {
    repo = MockMeterReportRepo();
    usecase = SubmitMeterReports(repo);
    registerFallbackValue(tMeterReports);
    registerFallbackValue(tToken);
  });

  test(
    'should call the [MeterReportRepo.submitMeterReports]',
    () async {
      when(
        () => repo.submitMeterReports(
          meterReports: any(named: "meterReports"),
          token: any(named: "token"),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(
        const SubmitMeterReportsParams(
          meterReports: tMeterReports,
          token: tToken,
        ),
      );
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.submitMeterReports(
          meterReports: any(named: "meterReports"),
          token: any(named: "token"),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}

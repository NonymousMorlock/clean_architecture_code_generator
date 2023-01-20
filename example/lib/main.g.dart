// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// UsecaseGenerator
// **************************************************************************

class GetStaff extends UsecaseWithParams<void, GetStaffParams> {
  const GetStaff(this._repo);

  final Usecase _repo;

  @override
  FunctionalFuture<void> call(GetStaffParams params) => _repo.getStaff(params);
}

class GetStaffParams extends Equatable {
  const GetStaffParams({
    required this.name,
    required this.eye,
  });

  final String name;
  final String eye;

  @override
  List<dynamic> get props => [
        name,
        eye,
      ];
}

class RemoveStaff extends UsecaseWithParams<String, String> {
  const RemoveStaff(this._repo);

  final Usecase _repo;

  @override
  FunctionalFuture<String> call(String params) => _repo.removeStaff(params);
}

class GoRoute extends UsecaseWithoutParams<String> {
  const GoRoute(this._repo);

  final Usecase _repo;

  @override
  FunctionalFuture<String> call() => _repo.goRoute();
}

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:example/repo_gen.dart';
import 'package:flutter/widgets.dart';
import 'package:example/usecase.dart';

part 'repo_gen.g.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;

@repoGen
@usecaseGen
@usecaseTestGen
@repoImplGen
@remoteSrcGen
class ProjectRepoTBG {
  external ResultFuture<void> addProject(Project project);

  external ResultFuture<void> editProjectDetails(Project updatedProject);

  external ResultFuture<void> deleteProject(String projectId);

  external ResultStream<List<Project>> getProjects();

  external ResultFuture<Project> getProjectById(String projectId);

  external ResultFuture<List<Client>> getClients();

  external ResultFuture<List<Milestone>> getMilestones(String projectId);

  external ResultFuture<Milestone> getMilestoneById({
    required String projectId,
    required String milestoneId,
  });
}

class Milestone {}

class Client {}

class Project {}

class Material {}

class ExamQuestion {}

class UserExam {}

class Exam {}

class Either<T, R> {}

class Failure {}

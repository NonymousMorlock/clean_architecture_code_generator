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
class ProjectRepoTBG {
  external FunctionalFuture<void> addProject(Project project);

  external FunctionalFuture<void> editProjectDetails(Project updatedProject);

  external FunctionalFuture<void> deleteProject(String projectId);

  external FunctionalFuture<List<Project>> getProjects();

  external FunctionalFuture<Project> getProjectById(String projectId);

  external FunctionalFuture<List<Client>> getClients();

  external FunctionalFuture<List<Milestone>> getMilestones(String projectId);

  external FunctionalFuture<Milestone> getMilestoneById({
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

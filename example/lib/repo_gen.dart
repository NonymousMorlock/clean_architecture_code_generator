import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:example/repo_gen.dart';
import 'package:example/typedefs.dart';
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

  external ResultFuture<void> editProjectDetails(DataMap updatedProject);

  external ResultFuture<void> deleteProject(String projectId);

  external ResultStream<List<Project>> getProjects();

  external ResultFuture<Project> getProjectById(String projectId);
}

@repoGen
@usecaseGen
@usecaseTestGen
@repoImplGen
@remoteSrcGen
class MilestoneRepoTBG {
  external ResultFuture<void> addMilestone(Milestone milestone);

  external ResultFuture<void> editMilestone(DataMap updatedMilestone);

  external ResultFuture<List<Milestone>> getMilestones(String projectId);

  external ResultFuture<void> deleteMilestone({
    required String projectId,
    required String milestoneId,
  });

  external ResultFuture<Milestone> getMilestoneById({
    required String projectId,
    required String milestoneId,
  });
}

@repoGen
@usecaseGen
@usecaseTestGen
@repoImplGen
@remoteSrcGen
class ClientRepoTBG {
  external ResultFuture<void> addClient(Client client);

  external ResultFuture<void> editClient(DataMap updatedClient);

  external ResultFuture<void> deleteClient(String clientId);

  external ResultFuture<Client> getClientById(String clientId);

  external ResultFuture<List<Client>> getClients();

  external ResultFuture<List<Project>> getClientProjects();
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

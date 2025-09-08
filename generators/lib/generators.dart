library generators;

import 'package:build/build.dart';
import 'package:generators/src/generators/cubit_generator.dart';
import 'package:generators/src/generators/data_src_impl_generator.dart';
import 'package:generators/src/generators/entity_generator.dart';
import 'package:generators/src/generators/injection_generator.dart';
import 'package:generators/src/generators/local_data_src_generator.dart';
import 'package:generators/src/generators/model_generator.dart';
import 'package:generators/src/generators/model_test_generator.dart';
import 'package:generators/src/generators/repo_generator.dart';
import 'package:generators/src/generators/repo_impl_generator.dart';
import 'package:generators/src/generators/repo_impl_test_generator.dart';
import 'package:generators/src/generators/usecase_generator.dart';
import 'package:generators/src/generators/usecase_test_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder generateEntityClass(BuilderOptions options) =>
    SharedPartBuilder([EntityGenerator()], 'ent');

Builder generateModelClass(BuilderOptions options) =>
    SharedPartBuilder([ModelGenerator()], 'model');

Builder generateUsecases(BuilderOptions options) =>
    SharedPartBuilder([UsecaseGenerator()], 'usecase');

Builder generateUsecasesTest(BuilderOptions options) =>
    SharedPartBuilder([UsecaseTestGenerator()], 'usecaseTests');

Builder generateRepoImpl(BuilderOptions options) =>
    SharedPartBuilder([RepoImplGenerator()], 'repoImpl');

Builder generateRemoteDataSrc(BuilderOptions options) =>
    SharedPartBuilder([RemoteDataSrcGenerator()], 'remoteDataSrc');

Builder generateRepository(BuilderOptions options) =>
    SharedPartBuilder([RepoGenerator()], 'repo');

Builder generateModelTest(BuilderOptions options) =>
    SharedPartBuilder([ModelTestGenerator()], 'modelTests');

Builder generateLocalDataSrc(BuilderOptions options) =>
    SharedPartBuilder([LocalDataSrcGenerator()], 'localDataSrc');

Builder generateInjectionContainer(BuilderOptions options) =>
    SharedPartBuilder([InjectionGenerator()], 'injection');

Builder generateCubit(BuilderOptions options) =>
    SharedPartBuilder([CubitGenerator()], 'cubit');

Builder generateRepoImplTest(BuilderOptions options) =>
    SharedPartBuilder([RepoImplTestGenerator()], 'repoImplTest');

/// Clean Architecture code generators for Dart/Flutter projects
library;

import 'package:build/build.dart';
// Import generator classes for builder functions
import 'package:generators/src/generators/adapter_generator.dart';
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

// Core exports
export 'core/config/generator_config.dart';
export 'core/services/feature_file_writer.dart';
export 'core/services/functions.dart';
export 'core/services/string_extensions.dart';
export 'core/utils/utils.dart';
// Generator exports
export 'src/generators/adapter_generator.dart';
export 'src/generators/data_src_impl_generator.dart';
export 'src/generators/entity_generator.dart';
export 'src/generators/injection_generator.dart';
export 'src/generators/local_data_src_generator.dart';
export 'src/generators/model_generator.dart';
export 'src/generators/model_test_generator.dart';
export 'src/generators/repo_generator.dart';
export 'src/generators/repo_impl_generator.dart';
export 'src/generators/repo_impl_test_generator.dart';
export 'src/generators/usecase_generator.dart';
export 'src/generators/usecase_test_generator.dart';
// Model exports
export 'src/models/field.dart';
export 'src/models/function.dart';
// Visitor exports
export 'src/visitors/model_visitor.dart';
export 'src/visitors/repo_visitor.dart';

// Builder functions for build.yaml

/// Builder function for generating entity classes from model annotations.
Builder generateEntityClass(BuilderOptions options) =>
    SharedPartBuilder([EntityGenerator()], 'ent');

/// Builder function for generating model classes from entity annotations.
Builder generateModelClass(BuilderOptions options) =>
    SharedPartBuilder([ModelGenerator()], 'model');

/// Builder function for generating use case classes from repository
/// annotations.
Builder generateUsecases(BuilderOptions options) =>
    SharedPartBuilder([UsecaseGenerator()], 'usecase');

/// Builder function for generating use case test files.
Builder generateUsecasesTest(BuilderOptions options) =>
    SharedPartBuilder([UsecaseTestGenerator()], 'usecaseTests');

/// Builder function for generating repository implementation classes.
Builder generateRepoImpl(BuilderOptions options) =>
    SharedPartBuilder([RepoImplGenerator()], 'repoImpl');

/// Builder function for generating remote data source classes.
Builder generateRemoteDataSrc(BuilderOptions options) =>
    SharedPartBuilder([RemoteDataSrcGenerator()], 'remoteDataSrc');

/// Builder function for generating repository interface classes.
Builder generateRepository(BuilderOptions options) =>
    SharedPartBuilder([RepoGenerator()], 'repo');

/// Builder function for generating model test files.
Builder generateModelTest(BuilderOptions options) =>
    SharedPartBuilder([ModelTestGenerator()], 'modelTests');

/// Builder function for generating local data source classes.
Builder generateLocalDataSrc(BuilderOptions options) =>
    SharedPartBuilder([LocalDataSrcGenerator()], 'localDataSrc');

/// Builder function for generating dependency injection container code.
Builder generateInjectionContainer(BuilderOptions options) =>
    SharedPartBuilder([InjectionGenerator()], 'injection');

/// Builder function for generating interface adapter classes.
Builder generateAdapter(BuilderOptions options) =>
    SharedPartBuilder([AdapterGenerator()], 'adapter');

/// Builder function for generating repository implementation test files.
Builder generateRepoImplTest(BuilderOptions options) =>
    SharedPartBuilder([RepoImplTestGenerator()], 'repoImplTest');

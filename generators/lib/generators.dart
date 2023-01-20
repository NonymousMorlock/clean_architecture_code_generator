library generators;

import 'package:build/build.dart';
import 'package:generators/src/entity_generator.dart';
import 'package:generators/src/model_generator.dart';
import 'package:generators/src/usecase_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder generateEntityClass(BuilderOptions options) =>
    SharedPartBuilder([EntityGenerator()], 'ent');

Builder generateModelClass(BuilderOptions options) =>
    SharedPartBuilder([ModelGenerator()], 'model');

Builder generateUsecases(BuilderOptions options) =>
    SharedPartBuilder([UsecaseGenerator()], 'usecase');

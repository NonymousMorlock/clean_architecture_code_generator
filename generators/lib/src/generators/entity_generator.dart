import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/class_builder_extensions.dart';
import 'package:generators/core/extensions/model_visitor_extensions.dart';
import 'package:generators/core/extensions/param_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating entity classes from model annotations.
///
/// Processes classes annotated with `@EntityGenAnnotation` and generates
/// corresponding entity classes in the domain layer.
class EntityGenerator extends GeneratorForAnnotation<EntityGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target non-classes.',
      );
    }

    final visitor = ModelVisitor();

    final constructor = element.unnamedConstructor;

    if (constructor != null) {
      visitor.visitConstructorElement(constructor);
    } else {
      stderr.writeln(
        '[EntityGenerator] Error: No default constructor found for '
        '${element.name}',
      );
      return '// Error: No default constructor found for ${element.name}';
    }

    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');

    var ignoreMultiFileCheck = false;

    if (config.multiFileOutput.enabled && !config.featureScaffolding.enabled) {
      // throw InvalidGenerationSourceError(
      //   'Multi-file output requires feature scaffolding to '
      //   'be enabled in the configuration, if you are going to be '
      //   'generating models and entities',
      // );
      stderr.writeln(
        '[EntityGenerator] Multi-file output requires feature scaffolding to '
        'be enabled in the configuration. Ignoring multi-file setting.',
      );
      ignoreMultiFileCheck = true;
    }

    String? associatedFeatureName;

    // Normalize the class name: UserTBG -> User -> user
    final normalisedName = visitor.className
        .replaceAll('TBG', '')
        .replaceAll('Model', '');

    for (final featureEntry in config.featureScaffolding.features.entries) {
      final featureName = featureEntry.key;
      final definition = featureEntry.value;
      if (definition.entities.contains(normalisedName.toLowerCase())) {
        associatedFeatureName = featureName;
        break;
      }
    }

    if (associatedFeatureName == null) {
      stderr.writeln(
        '[EntityGenerator] Warning: No associated feature found for entity '
        '$normalisedName. Generated entity will not be placed in a '
        'feature-specific directory.',
      );
      ignoreMultiFileCheck = true;
    }

    final writer = FeatureFileWriter(config: config, buildStep: buildStep);

    if (writer.isMultiFileEnabled && !ignoreMultiFileCheck) {
      return _generateMultiFile(
        visitor: visitor,
        writer: writer,
        normalisedName: normalisedName,
        associatedFeatureName: associatedFeatureName!,
      );
    }

    final entityClass = _generateEntityClass(
      visitor: visitor,
      className: normalisedName,
    );
    return writer.resolveGeneratedCode(
      library: Library((library) => library.body.add(entityClass)),
    );
  }

  String _generateMultiFile({
    required ModelVisitor visitor,
    required FeatureFileWriter writer,
    required String normalisedName,
    required String associatedFeatureName,
  }) {
    // For compositions in the entity, we need to import all custom entities
    final (:imports, :importComments) = writer.generateSmartDomainEntityImports(
      candidates: visitor.discoverRequiredEntities(),
      featureName: associatedFeatureName,
    );

    final entityClass = _generateEntityClass(
      visitor: visitor,
      className: normalisedName,
    );

    final entityPath = writer.getEntityPath(
      featureName: associatedFeatureName,
      entityName: normalisedName,
    );

    final completeFile = writer.resolveGeneratedCode(
      library: Library((library) {
        library
          ..body.add(entityClass)
          ..comments.addAll(importComments)
          ..directives.addAll(imports.map(Directive.import));
      }),
    );

    try {
      writer.writeToFile(entityPath, completeFile);

      return '// Entity class written to: $entityPath\n';
    } on Exception catch (e, s) {
      stderr
        ..writeln(
          '[EntityGenerator] ERROR: Could not write entity files: $e',
        )
        ..writeln('[EntityGenerator] Stack trace: $s');
      return '// Error: Could not write entity class to file: $e\n';
    }
  }

  Class _generateEntityClass({
    required ModelVisitor visitor,
    required String className,
  }) {
    return Class((classBuilder) {
      classBuilder
        ..name = className
        ..extend = const Reference('Equatable')
        ..constructors.addAll(_generateConstructors(visitor: visitor))
        ..fields.addAll(
          visitor.params.map((param) {
            return Field((field) {
              field
                ..name = param.name.camelCase
                ..type = TypeReference((ref) {
                  ref
                    ..symbol = param.type
                    ..isNullable = param.isNullable;
                })
                ..modifier = FieldModifier.final$;
            });
          }),
        )
        ..addEquatableProps(params: visitor.params);
    });
  }

  List<Constructor> _generateConstructors({required ModelVisitor visitor}) {
    return [
      Constructor((constructor) {
        constructor
          ..constant = true
          ..optionalParameters.addAll(
            visitor.params.map((param) {
              return Parameter((paramBuilder) {
                paramBuilder
                  ..name = param.name.camelCase
                  ..named = true
                  ..required = !param.isNullable && !param.hasDefaultValue
                  ..defaultTo = param.hasDefaultValue
                      ? Code(param.defaultValueCode!)
                      : null
                  ..toThis = true;
              });
            }),
          );
      }),
      Constructor((constructor) {
        constructor
          ..name = 'empty'
          ..constant = visitor.params.every(
            (param) => param.rawType.isConst || param.isNullable,
          )
          ..initializers.add(
            refer('this').call(
              [],
              {
                for (final param in visitor.params)
                  param.name.camelCase: param.fallbackValue(),
              },
            ).code,
          );
      }),
    ];
  }
}

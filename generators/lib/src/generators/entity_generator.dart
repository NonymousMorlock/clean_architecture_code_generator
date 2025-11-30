// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
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
    final normalizedName = visitor.className
        .replaceAll('TBG', '')
        .replaceAll('Model', '');

    for (final featureEntry in config.featureScaffolding.features.entries) {
      final featureName = featureEntry.key;
      final definition = featureEntry.value;
      if (definition.entities.contains(normalizedName.toLowerCase())) {
        associatedFeatureName = featureName;
        break;
      }
    }

    if (associatedFeatureName == null) {
      stderr.writeln(
        '[EntityGenerator] Warning: No associated feature found for entity '
        '$normalizedName. Generated entity will not be placed in a '
        'feature-specific directory.',
      );
      ignoreMultiFileCheck = true;
    }

    final writer = FeatureFileWriter(config, buildStep);

    final buffer = StringBuffer();

    if (writer.isMultiFileEnabled && !ignoreMultiFileCheck) {
      return _generateMultiFile(
        visitor: visitor,
        writer: writer,
        normalizedName: normalizedName,
        associatedFeatureName: associatedFeatureName,
      );
    }

    _generateEntityClass(
      buffer: buffer,
      visitor: visitor,
      className: normalizedName,
    );
    return buffer.toString();
  }

  String _generateMultiFile({
    required ModelVisitor visitor,
    required FeatureFileWriter writer,
    required String normalizedName,
    required String? associatedFeatureName,
  }) {
    final buffer = StringBuffer()
      ..writeln(
        "import 'package:equatable/equatable.dart';",
      );
    _generateEntityClass(
      buffer: buffer,
      visitor: visitor,
      className: normalizedName,
    );

    final entityPath = writer.getEntityPath(
      featureName: associatedFeatureName!,
      entityName: normalizedName,
    );

    try {
      writer.writeToFile(entityPath, buffer.toString());

      stdout.writeln('[EntityGenerator] Successfully wrote files');
      return '// Entity class written to: $entityPath\n';
    } on Exception catch (e, s) {
      stderr
        ..writeln(
          '[EntityGenerator] ERROR: Could not write adapter files: $e',
        )
        ..writeln('[EntityGenerator] Stack trace: $s');
      return '// Error: Could not write entity class to file: $e\n';
    }
  }

  void _generateEntityClass({
    required StringBuffer buffer,
    required ModelVisitor visitor,
    required String className,
  }) {
    final length = visitor.fields.length;
    buffer
      ..writeln('class $className extends Equatable {')
      ..writeln('const $className({');
    for (var i = 0; i < length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('${field.isRequired ? 'required ' : ''}this.$name,');
    }
    buffer
      ..writeln('});')
      ..writeln()
      ..writeln('$className.empty()')
      ..writeln(':');
    for (var i = 0; i < length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      // final field = visitor.fieldProperties[name]!;
      final defaultValue = type.fallbackValue;
      final emptyConstructor = '$type.empty()';
      final optionalQuote =
          defaultValue is String && defaultValue.toLowerCase() == 'test string'
          ? '"'
          : '';
      buffer.writeln(
        '$name = $optionalQuote'
        '${defaultValue ?? emptyConstructor}'
        '$optionalQuote${i == length - 1 ? ';' : ','}',
      );
    }
    buffer.writeln();
    for (var i = 0; i < length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('final $type${field.isRequired ? '' : '?'} $name;');
    }
    buffer
      ..writeln()
      ..writeln('@override')
      ..writeln('List<dynamic> get props => [');
    for (var i = 0; i < length; i++) {
      final type = visitor.fields.values.elementAt(i);
      if (type.toLowerCase().startsWith('list')) continue;
      final name = visitor.fields.keys.elementAt(i).camelCase;

      buffer.writeln('$name,');
    }
    buffer
      ..writeln('];')
      ..writeln('}');
  }
}

// We need to import from build package internals to access BuildStep
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/model_visitor_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/src/visitors/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating model classes from entity annotations.
///
/// Processes classes annotated with `@ModelGenAnnotation` and generates
/// corresponding model classes in the data layer with JSON serialization.
class ModelGenerator extends GeneratorForAnnotation<ModelGenAnnotation> {
  // DIDN'T SOLVE MY ISSUE, HAD TO CHANGE BUILD.YAML CONFIG
  // static const _checker = TypeChecker.fromRuntime(ModelGenAnnotation);
  // unfortunately, after dart 3 update, the generateForAnnotatedElement
  // override was no longer enough to generate the model class, so we had to
  // override generate as well.
  // @override
  // Future<String> generate(LibraryReader library, BuildStep buildStep) async {
  //   final buffer = StringBuffer();
  //   for (var element in library.allElements) {
  //     if (element is ClassElement && _checker
  //     .hasAnnotationOfExact(element)) {
  //       final visitor = ModelVisitor();
  //       element.visitChildren(visitor);
  //       constructor(buffer, visitor);
  //     }
  //   }
  //   return buffer.toString();
  // }

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
        '[ModelGenerator] Error: No default constructor found for '
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
        '[ModelGenerator] Multi-file output requires feature scaffolding to '
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
        '[ModelGenerator] Warning: No associated feature found for entity '
        '$normalisedName. Generated entity will not be placed in a '
        'feature-specific directory.',
      );
      ignoreMultiFileCheck = true;
    }

    final writer = FeatureFileWriter(config, buildStep);

    final buffer = StringBuffer();

    if (writer.isMultiFileEnabled && !ignoreMultiFileCheck) {
      return _generateMultiFile(
        visitor: visitor,
        config: config,
        writer: writer,
        normalisedName: normalisedName,
        associatedFeatureName: associatedFeatureName!,
      );
    }

    _generateModel(
      buffer: buffer,
      visitor: visitor,
      normalisedName: normalisedName,
    );
    return buffer.toString();
  }

  String _generateMultiFile({
    required ModelVisitor visitor,
    required GeneratorConfig config,
    required FeatureFileWriter writer,
    required String normalisedName,
    required String associatedFeatureName,
  }) {
    final buffer = StringBuffer()
      ..writeln("import 'package:${config.appName}/core/typedefs.dart';")
      ..writeln("import 'dart:convert';");

    // Import the entity this model is based on
    writer
        .getSmartEntityImports(
          entities: {normalisedName},
          currentFeature: associatedFeatureName,
        )
        .forEach(buffer.writeln);

    writer
        .getSmartEntityImports(
          isModel: true,
          entities: visitor.discoverRequiredEntities(),
          currentFeature: associatedFeatureName,
        )
        .forEach(buffer.writeln);

    _generateModel(
      buffer: buffer,
      visitor: visitor,
      normalisedName: normalisedName,
    );

    final modelPath = writer.getModelPath(
      featureName: associatedFeatureName,
      entityName: normalisedName,
    );

    try {
      writer.writeToFile(modelPath, buffer.toString());

      stdout.writeln('[ModelGenerator] Successfully wrote files');
      return '// Model class written to: $modelPath\n';
    } on Exception catch (e, s) {
      stderr
        ..writeln(
          '[ModelGenerator] ERROR: Could not write model files: $e',
        )
        ..writeln('[ModelGenerator] Stack trace: $s');
      return '// Error: Could not write model class to file: $e\n';
    }
  }

  /// Generates the model class and all its methods.
  ///
  /// Creates the main constructor, empty constructor, and all
  /// serialization/deserialization methods.
  void _generateModel({
    required StringBuffer buffer,
    required ModelVisitor visitor,
    required String normalisedName,
  }) {
    final modelClassName = '${normalisedName}Model';
    final length = visitor.fields.length;

    buffer
      ..writeln('class $modelClassName extends $normalisedName {')
      ..writeln('const $modelClassName({');
    for (var i = 0; i < length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final field = visitor.fieldProperties[name]!;
      buffer.writeln('${field.isRequired ? 'required ' : ''}super.$name,');
    }
    buffer
      ..writeln('});')
      ..writeln()
      ..writeln('$modelClassName.empty()')
      ..writeln(':')
      ..writeln('this(');
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
        '$name: '
        '$optionalQuote'
        '${defaultValue ?? emptyConstructor}'
        '$optionalQuote${i == length - 1 ? ',);' : ','}',
      );
    }
    buffer.writeln();
    fromJson(buffer: buffer, visitor: visitor, normalisedName: normalisedName);
    buffer.writeln();
    fromMap(buffer: buffer, visitor: visitor, normalisedName: normalisedName);
    buffer.writeln();
    copyWith(buffer: buffer, visitor: visitor, normalisedName: normalisedName);
    buffer.writeln();
    toMap(buffer, visitor);
    buffer.writeln();
    toJson(buffer);
    buffer.writeln();

    // Add DateTime parsing helper method
    _generateDateTimeParsingHelper(buffer);

    buffer.writeln('}');
  }

  /// Generates the fromMap factory constructor.
  ///
  /// Creates a factory that deserializes a model from a Map,
  /// handling various data types including DateTime and numeric conversions.
  void fromMap({
    required StringBuffer buffer,
    required ModelVisitor visitor,
    required String normalisedName,
  }) {
    final modelClassName = '${normalisedName}Model';
    buffer
      ..writeln('$modelClassName.fromMap(DataMap map)')
      ..writeln(': this(');
    for (var i = 0; i < visitor.fields.length; i++) {
      final type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i);
      final field = visitor.fieldProperties[name.camelCase]!;

      if (type.isCustomType) {
        if (type.toLowerCase().startsWith('list')) {
          var value =
              "List<DataMap>.from(map['$name'] as List<dynamic>).map("
              '${type.innerType}Model.fromMap).toList()';
          if (!field.isRequired) {
            value = "map['$name'] != null ? $value : null";
          }
          buffer.writeln('${name.camelCase}: $value,');
        } else {
          var value = "${type}Model.fromMap(map['$name'] as DataMap)";
          if (!field.isRequired) {
            value = "map['$name'] != null ? $value : null";
          }
          buffer.writeln('${name.camelCase}: $value,');
        }
      } else if (type.toLowerCase().startsWith('list')) {
        var value = "$type.from(map['$name'] as List<dynamic>)";
        if (!field.isRequired) {
          value = "map['$name'] != null ? $value : null";
        }
        buffer.writeln('${name.camelCase}: $value,');
      } else if (type.toLowerCase().startsWith('int')) {
        var value = "(map['$name'] as num).toInt()";
        if (!field.isRequired) {
          value = "(map['$name'] as num?)?.toInt()";
        }
        buffer.writeln('${name.camelCase}: $value,');
      } else if (type.toLowerCase().startsWith('double')) {
        var value = "(map['$name'] as num).toDouble()";
        if (!field.isRequired) {
          value = "(map['$name'] as num?)?.toDouble()";
        }
        buffer.writeln('${name.camelCase}: $value,');
      } else if (type.toLowerCase().startsWith('datetime')) {
        // Enhanced DateTime parsing to handle multiple API formats
        if (!field.isRequired) {
          buffer.writeln(
            "${name.camelCase}: map['$name'] == null ? null :"
            " _parseDateTime(map['$name']),",
          );
        } else {
          buffer.writeln("${name.camelCase}: _parseDateTime(map['$name']),");
        }
      } else {
        buffer.writeln(
          "${name.camelCase}: map['$name'] "
          "as $type${field.isRequired ? '' : '?'},",
        );
      }
    }
    buffer.writeln(');');
  }

  /// Generates the fromJson factory constructor.
  ///
  /// Creates a factory that deserializes a model from a JSON string.
  void fromJson({
    required StringBuffer buffer,
    required ModelVisitor visitor,
    required String normalisedName,
  }) {
    final modelClassName = '${normalisedName}Model';
    buffer
      ..writeln('factory $modelClassName.fromJson(String source) =>')
      ..writeln('$modelClassName.fromMap(jsonDecode(source) as DataMap);');
  }

  /// Generates the toMap method.
  ///
  /// Creates a method that serializes the model to a Map,
  /// properly handling DateTime conversion to ISO 8601 strings.
  void toMap(StringBuffer buffer, ModelVisitor visitor) {
    buffer
      ..writeln('DataMap toMap() {')
      ..writeln('return <String, dynamic>{');
    for (var i = 0; i < visitor.fields.length; i++) {
      final name = visitor.fields.keys.elementAt(i);
      final type = visitor.fields.values.elementAt(i);
      final field = visitor.fieldProperties[name.camelCase]!;

      if (type.isCustomType) {
        final initialDeclaration =
            "'$name': ${name.camelCase}${field.isRequired ? '' : '?'}";
        if (type.toLowerCase().startsWith('list')) {
          buffer.writeln(
            '$initialDeclaration.map((e) => e.toMap()).toList(),',
          );
        } else {
          buffer.writeln(
            '$initialDeclaration.toMap(),',
          );
        }
      } else if (type.toLowerCase().startsWith('datetime')) {
        buffer.writeln(
          "'$name': "
          "${name.camelCase}${field.isRequired ? '' : '?'}.toIso8601String(),",
        );
      } else {
        buffer.writeln("'$name': ${name.camelCase},");
      }
    }
    buffer
      ..writeln('};')
      ..writeln('}');
  }

  /// Generates the toJson method.
  ///
  /// Creates a method that serializes the model to a JSON string.
  void toJson(StringBuffer buffer) {
    buffer.writeln('String toJson() => jsonEncode(toMap());');
  }

  /// Generates the copyWith method.
  ///
  /// Creates a method that returns a new instance with updated values,
  /// following the immutable pattern.
  void copyWith({
    required StringBuffer buffer,
    required ModelVisitor visitor,
    required String normalisedName,
  }) {
    final modelClassName = '${normalisedName}Model';

    buffer.writeln('$modelClassName copyWith({');
    for (var i = 0; i < visitor.fields.length; i++) {
      var type = visitor.fields.values.elementAt(i);
      final name = visitor.fields.keys.elementAt(i).camelCase;
      final isCustomType = type.isCustomType;
      if (isCustomType) type = type.modelizeType;

      buffer.writeln('$type? $name,');
    }
    buffer
      ..writeln('}) {')
      ..writeln('return $modelClassName(');
    for (var i = 0; i < visitor.fields.length; i++) {
      final name = visitor.fields.keys.elementAt(i).camelCase;
      buffer.writeln('$name: $name ?? this.$name,');
    }
    buffer
      ..writeln(');')
      ..writeln('}');
  }

  void _generateDateTimeParsingHelper(StringBuffer buffer) {
    buffer
      ..writeln(
        '  // Helper method to parse DateTime from various API formats',
      )
      ..writeln('  static DateTime _parseDateTime(dynamic value) {')
      ..writeln('    if (value is String) {')
      ..writeln('      return DateTime.parse(value);')
      ..writeln('    } else if (value is int) {')
      ..writeln('      // Handle timestamp (milliseconds or seconds)')
      ..writeln('      return value > 1000000000000')
      ..writeln('          ? DateTime.fromMillisecondsSinceEpoch(value)')
      ..writeln(
        '          : DateTime.fromMillisecondsSinceEpoch(value * 1000);',
      )
      ..writeln('    } else if (value is double) {')
      ..writeln(
        '      return DateTime.fromMillisecondsSinceEpoch(value.toInt());',
      )
      ..writeln('    } else {')
      ..writeln(
        r"      throw FormatException('Invalid DateTime format: $value');",
      )
      ..writeln('    }')
      ..writeln('  }');
  }
}

import 'dart:io';
import 'package:yaml/yaml.dart';

class GeneratorConfig {
  GeneratorConfig({
    this.outputPath = 'lib',
    this.namingConvention = NamingConvention.camelCase,
    this.generateTests = true,
    this.generateDocs = false,
    this.customImports = const [],
    this.templateOverrides = const {},
    this.featureStructure = const DefaultFeatureStructure(),
    this.modelTestConfig = const ModelTestConfig(),
  });

  factory GeneratorConfig.fromFile(String configPath) {
    try {
      final file = File(configPath);
      if (!file.existsSync()) {
        return GeneratorConfig(); // Return default config
      }

      final yamlString = file.readAsStringSync();
      final yamlMap = loadYaml(yamlString) as Map<dynamic, dynamic>;
      
      return GeneratorConfig.fromMap(yamlMap);
    } catch (e) {
      print('Warning: Could not load config file. Using defaults. Error: $e');
      return GeneratorConfig();
    }
  }

  factory GeneratorConfig.fromMap(Map<dynamic, dynamic> map) {
    return GeneratorConfig(
      outputPath: map['output_path'] as String? ?? 'lib',
      namingConvention: _parseNamingConvention(map['naming_convention'] as String?),
      generateTests: map['generate_tests'] as bool? ?? true,
      generateDocs: map['generate_docs'] as bool? ?? false,
      customImports: (map['custom_imports'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
      templateOverrides: Map<String, String>.from(
        map['template_overrides'] as Map<dynamic, dynamic>? ?? {},
      ),
      featureStructure: FeatureStructure.fromMap(
        map['feature_structure'] as Map<dynamic, dynamic>? ?? {},
      ),
      modelTestConfig: ModelTestConfig.fromMap(
        map['model_test_config'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }

  final String outputPath;
  final NamingConvention namingConvention;
  final bool generateTests;
  final bool generateDocs;
  final List<String> customImports;
  final Map<String, String> templateOverrides;
  final FeatureStructure featureStructure;
  final ModelTestConfig modelTestConfig;

  static NamingConvention _parseNamingConvention(String? convention) {
    switch (convention?.toLowerCase()) {
      case 'snake_case':
        return NamingConvention.snakeCase;
      case 'pascal_case':
        return NamingConvention.pascalCase;
      case 'camel_case':
      default:
        return NamingConvention.camelCase;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'output_path': outputPath,
      'naming_convention': namingConvention.name,
      'generate_tests': generateTests,
      'generate_docs': generateDocs,
      'custom_imports': customImports,
      'template_overrides': templateOverrides,
      'feature_structure': featureStructure.toMap(),
    };
  }

  String toYaml() {
    final map = toMap();
    return '''
# Clean Architecture Code Generator Configuration

# Output directory for generated files (relative to project root)
output_path: ${map['output_path']}

# Naming convention for generated classes and files
# Options: camel_case, snake_case, pascal_case
naming_convention: ${map['naming_convention']}

# Whether to generate test files
generate_tests: ${map['generate_tests']}

# Whether to generate documentation
generate_docs: ${map['generate_docs']}

# Custom imports to add to generated files
custom_imports:
${customImports.map((import) => '  - $import').join('\n')}

# Template overrides for custom code generation
template_overrides:
${templateOverrides.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}

# Feature structure configuration
feature_structure:
${featureStructure.toYamlString().split('\n').map((line) => '  $line').join('\n')}
''';
  }
}

enum NamingConvention {
  camelCase,
  snakeCase,
  pascalCase,
}

class FeatureStructure {
  const FeatureStructure({
    required this.dataPath,
    required this.domainPath,
    required this.presentationPath,
    required this.useSubfolders,
  });

  factory FeatureStructure.fromMap(Map<dynamic, dynamic> map) {
    return FeatureStructure(
      dataPath: map['data_path'] as String? ?? 'data',
      domainPath: map['domain_path'] as String? ?? 'domain',
      presentationPath: map['presentation_path'] as String? ?? 'presentation',
      useSubfolders: map['use_subfolders'] as bool? ?? true,
    );
  }

  final String dataPath;
  final String domainPath;
  final String presentationPath;
  final bool useSubfolders;

  Map<String, dynamic> toMap() {
    return {
      'data_path': dataPath,
      'domain_path': domainPath,
      'presentation_path': presentationPath,
      'use_subfolders': useSubfolders,
    };
  }

  String toYamlString() {
    return '''
data_path: $dataPath
domain_path: $domainPath
presentation_path: $presentationPath
use_subfolders: $useSubfolders''';
  }
}

class DefaultFeatureStructure extends FeatureStructure {
  const DefaultFeatureStructure()
      : super(
          dataPath: 'data',
          domainPath: 'domain',
          presentationPath: 'presentation',
          useSubfolders: true,
        );
}

class ModelTestConfig {
  const ModelTestConfig({
    this.useFixtureBasedTests = true,
    this.generateNullSafetyTests = true,
    this.modelConfigs = const {},
    this.defaults = const ModelTestDefaults(),
  });

  factory ModelTestConfig.fromMap(Map<dynamic, dynamic> map) {
    final global = map['global'] as Map<dynamic, dynamic>? ?? {};
    final modelConfigs = <String, ModelFieldTypeConfig>{};

    // Parse model-specific configurations
    for (final entry in map.entries) {
      if (entry.key != 'global' && entry.key != 'defaults') {
        final modelName = entry.key as String;
        final modelMap = entry.value as Map<dynamic, dynamic>? ?? {};
        modelConfigs[modelName] = ModelFieldTypeConfig.fromMap(modelMap);
      }
    }

    return ModelTestConfig(
      useFixtureBasedTests: global['use_fixture_based_tests'] as bool? ?? true,
      generateNullSafetyTests:
          global['generate_null_safety_tests'] as bool? ?? true,
      modelConfigs: modelConfigs,
      defaults: ModelTestDefaults.fromMap(
        map['defaults'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }

  final bool useFixtureBasedTests;
  final bool generateNullSafetyTests;
  final Map<String, ModelFieldTypeConfig> modelConfigs;
  final ModelTestDefaults defaults;

  String getFieldType(String modelName, String fieldName, String dartType) {
    // Check model-specific configuration first
    final modelConfig = modelConfigs[modelName.toLowerCase()];
    if (modelConfig != null) {
      final fieldType = modelConfig.fieldTypes[fieldName];
      if (fieldType != null) {
        return fieldType;
      }
    }

    // Fall back to defaults based on dart type
    if (dartType.toLowerCase().contains('datetime')) {
      return defaults.datetimeFormat;
    } else if (dartType.toLowerCase().contains('double')) {
      return defaults.numberFormat;
    } else if (dartType.toLowerCase().contains('int')) {
      return 'int';
    }

    return ''; // Use default handling
  }
}

class ModelFieldTypeConfig {
  const ModelFieldTypeConfig({
    this.fieldTypes = const {},
  });

  factory ModelFieldTypeConfig.fromMap(Map<dynamic, dynamic> map) {
    final fieldTypesMap = map['field_types'] as Map<dynamic, dynamic>? ?? {};
    return ModelFieldTypeConfig(
      fieldTypes: Map<String, String>.from(fieldTypesMap),
    );
  }

  final Map<String, String> fieldTypes;
}

class ModelTestDefaults {
  const ModelTestDefaults({
    this.datetimeFormat = 'iso_string',
    this.numberFormat = 'double',
  });

  factory ModelTestDefaults.fromMap(Map<dynamic, dynamic> map) {
    return ModelTestDefaults(
      datetimeFormat: map['datetime_format'] as String? ?? 'iso_string',
      numberFormat: map['number_format'] as String? ?? 'double',
    );
  }

  final String datetimeFormat;
  final String numberFormat;
}

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
    );
  }

  final String outputPath;
  final NamingConvention namingConvention;
  final bool generateTests;
  final bool generateDocs;
  final List<String> customImports;
  final Map<String, String> templateOverrides;
  final FeatureStructure featureStructure;

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

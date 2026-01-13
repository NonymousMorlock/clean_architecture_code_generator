import 'dart:io';

import 'package:generators/core/extensions/string_extensions.dart';
import 'package:yaml/yaml.dart';

/// Configuration for the code generators.
///
/// This class loads and manages configuration from `clean_arch_config.yaml`
/// and provides settings for all generators including naming conventions,
/// feature structure, test generation, and multi-file output.
class GeneratorConfig {
  /// Creates a [GeneratorConfig] with the given settings.
  ///
  /// All parameters are optional and have sensible defaults.
  GeneratorConfig({
    this.appName = 'your_app',
    this.outputPath = 'lib',
    this.namingConvention = NamingConvention.camelCase,
    this.generateTests = true,
    this.generateDocs = false,
    this.customImports = const [],
    this.templateOverrides = const {},
    this.featureStructure = const DefaultFeatureStructure(),
    this.modelTestConfig = const ModelTestConfig(),
    this.remoteDataSourceConfig = const RemoteDataSourceConfig(),
    this.multiFileOutput = const MultiFileOutputConfig(),
    this.featureScaffolding = const FeatureScaffoldingConfig(),
  });

  /// Creates a [GeneratorConfig] from a YAML configuration file.
  ///
  /// If the file doesn't exist or cannot be parsed, returns a default
  /// configuration and logs a warning to stderr.
  factory GeneratorConfig.fromFile(String configPath) {
    try {
      final file = File(configPath);
      if (!file.existsSync()) {
        return GeneratorConfig(); // Return default config
      }

      final yamlString = file.readAsStringSync();
      final yamlMap = Map<dynamic, dynamic>.from(loadYaml(yamlString) as Map);

      if (yamlMap['app_name'] == null) {
        final pubspecFile = File('pubspec.yaml');
        if (pubspecFile.existsSync()) {
          final pubspecYamlString = pubspecFile.readAsStringSync();
          final pubspecYamlMap =
              loadYaml(pubspecYamlString) as Map<dynamic, dynamic>;
          final appName = pubspecYamlMap['name'] as String?;
          if (appName != null) {
            yamlMap['app_name'] = appName;
          }
        }
      }

      return GeneratorConfig.fromMap(yamlMap);
    } on Exception catch (e) {
      // Use stderr instead of print for warnings in production code
      stderr.writeln(
        'Warning: Could not load config file. Using defaults. Error: $e',
      );
      return GeneratorConfig();
    }
  }

  /// Creates a [GeneratorConfig] from a map of configuration values.
  ///
  /// This is typically called by `fromFile` after parsing the YAML.
  factory GeneratorConfig.fromMap(Map<dynamic, dynamic> map) {
    return GeneratorConfig(
      appName: map['app_name'] as String? ?? 'your_app',
      outputPath: map['output_path'] as String? ?? 'lib',
      namingConvention: _parseNamingConvention(
        map['naming_convention'] as String?,
      ),
      generateTests: map['generate_tests'] as bool? ?? true,
      generateDocs: map['generate_docs'] as bool? ?? false,
      customImports:
          (map['custom_imports'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      templateOverrides: Map<String, String>.from(
        map['template_overrides'] as Map<dynamic, dynamic>? ?? {},
      ),
      featureStructure: FeatureStructure.fromMap(
        map['feature_structure'] as Map<dynamic, dynamic>? ?? {},
      ),
      modelTestConfig: ModelTestConfig.fromMap(
        map['model_test_config'] as Map<dynamic, dynamic>? ?? {},
      ),
      remoteDataSourceConfig: RemoteDataSourceConfig.fromMap(
        map['remote_data_source'] as Map<dynamic, dynamic>? ?? {},
      ),
      multiFileOutput: MultiFileOutputConfig.fromMap(
        map['multi_file_output'] as Map<dynamic, dynamic>? ?? {},
      ),
      featureScaffolding: FeatureScaffoldingConfig.fromMap(
        map['feature_scaffolding'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }

  /// The name of the application.
  final String appName;

  /// The base output path for generated files.
  final String outputPath;

  /// The naming convention to use for generated code.
  final NamingConvention namingConvention;

  /// Whether to generate test files.
  final bool generateTests;

  /// Whether to generate documentation.
  final bool generateDocs;

  /// List of custom imports to include in generated files.
  final List<String> customImports;

  /// Map of template overrides for customizing generated code.
  final Map<String, String> templateOverrides;

  /// Configuration for the feature directory structure.
  final FeatureStructure featureStructure;

  /// Configuration for model test generation.
  final ModelTestConfig modelTestConfig;

  /// Configuration for remote data source generation.
  final RemoteDataSourceConfig remoteDataSourceConfig;

  /// Configuration for multi-file output mode.
  final MultiFileOutputConfig multiFileOutput;

  /// Configuration for feature scaffolding.
  final FeatureScaffoldingConfig featureScaffolding;

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

  /// Converts this configuration to a map.
  Map<String, dynamic> toMap() {
    return {
      'app_name': appName,
      'output_path': outputPath,
      'naming_convention': namingConvention.name,
      'generate_tests': generateTests,
      'generate_docs': generateDocs,
      'custom_imports': customImports,
      'template_overrides': templateOverrides,
      'feature_structure': featureStructure.toMap(),
    };
  }

  /// Converts this configuration to a YAML string.
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

/// Naming convention options for generated code.
enum NamingConvention {
  /// camelCase naming (e.g., myVariable)
  camelCase,

  /// snake_case naming (e.g., my_variable)
  snakeCase,

  /// PascalCase naming (e.g., MyVariable)
  pascalCase,
}

/// Configuration for the feature directory structure.
///
/// Defines the paths for data, domain, and presentation layers
/// within a feature.
class FeatureStructure {
  /// Creates a [FeatureStructure] with the given paths.
  const FeatureStructure({
    required this.dataPath,
    required this.domainPath,
    required this.presentationPath,
    required this.useSubfolders,
  });

  /// Creates a [FeatureStructure] from a map of configuration values.
  factory FeatureStructure.fromMap(Map<dynamic, dynamic> map) {
    return FeatureStructure(
      dataPath: map['data_path'] as String? ?? 'data',
      domainPath: map['domain_path'] as String? ?? 'domain',
      presentationPath: map['presentation_path'] as String? ?? 'presentation',
      useSubfolders: map['use_subfolders'] as bool? ?? true,
    );
  }

  /// The path to the data layer directory.
  final String dataPath;

  /// The path to the domain layer directory.
  final String domainPath;

  /// The path to the presentation layer directory.
  final String presentationPath;

  /// Whether to use subfolders within each layer.
  final bool useSubfolders;

  /// Converts this feature structure to a map.
  Map<String, dynamic> toMap() {
    return {
      'data_path': dataPath,
      'domain_path': domainPath,
      'presentation_path': presentationPath,
      'use_subfolders': useSubfolders,
    };
  }

  /// Converts this feature structure to a YAML string.
  String toYamlString() {
    return '''
data_path: $dataPath
domain_path: $domainPath
presentation_path: $presentationPath
use_subfolders: $useSubfolders''';
  }
}

/// Default implementation of [FeatureStructure] with standard paths.
class DefaultFeatureStructure extends FeatureStructure {
  /// Creates a [DefaultFeatureStructure] with standard
  /// clean architecture paths.
  const DefaultFeatureStructure()
    : super(
        dataPath: 'data',
        domainPath: 'domain',
        presentationPath: 'presentation',
        useSubfolders: true,
      );
}

/// Configuration for model test generation.
///
/// Controls how test files are generated for model classes.
class ModelTestConfig {
  /// Creates a [ModelTestConfig] with the given settings.
  const ModelTestConfig({
    this.useFixtureBasedTests = true,
    this.generateNullSafetyTests = true,
    this.modelConfigs = const {},
    this.defaults = const ModelTestDefaults(),
  });

  /// Creates a [ModelTestConfig] from a map of configuration values.
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

  /// Whether to use fixture-based tests.
  final bool useFixtureBasedTests;

  /// Whether to generate null safety tests.
  final bool generateNullSafetyTests;

  /// Model-specific field type configurations.
  final Map<String, ModelFieldTypeConfig> modelConfigs;

  /// Default values for model test generation.
  final ModelTestDefaults defaults;

  /// Gets the field type for a specific model field.
  ///
  /// Checks model-specific configuration first, then falls back to defaults.
  String getFieldType({
    required String modelName,
    required String fieldName,
    required String dartType,
  }) {
    // Check model-specific configuration first
    final modelConfig = modelConfigs[modelName.toLowerCase()];
    if (modelConfig != null) {
      final fieldType = modelConfig.fieldTypes[fieldName];
      if (fieldType != null) {
        return fieldType;
      } else {
        final fieldType = modelConfig.fieldTypes[fieldName.camelCase];
        if (fieldType != null) {
          return fieldType;
        }
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

/// Configuration for field types in a specific model.
class ModelFieldTypeConfig {
  /// Creates a [ModelFieldTypeConfig] with the given field types.
  const ModelFieldTypeConfig({
    this.fieldTypes = const {},
  });

  /// Creates a [ModelFieldTypeConfig] from a map of configuration values.
  factory ModelFieldTypeConfig.fromMap(Map<dynamic, dynamic> map) {
    final fieldTypesMap = map['field_types'] as Map<dynamic, dynamic>? ?? {};
    return ModelFieldTypeConfig(
      fieldTypes: Map<String, String>.from(fieldTypesMap),
    );
  }

  /// Map of field names to their types.
  final Map<String, String> fieldTypes;
}

/// Default values for model test generation.
class ModelTestDefaults {
  /// Creates [ModelTestDefaults] with the given format settings.
  const ModelTestDefaults({
    this.datetimeFormat = 'iso_string',
    this.numberFormat = 'double',
  });

  /// Creates [ModelTestDefaults] from a map of configuration values.
  factory ModelTestDefaults.fromMap(Map<dynamic, dynamic> map) {
    return ModelTestDefaults(
      datetimeFormat: map['datetime_format'] as String? ?? 'iso_string',
      numberFormat: map['number_format'] as String? ?? 'double',
    );
  }

  /// The format to use for datetime fields (e.g., 'iso_string').
  final String datetimeFormat;

  /// The format to use for number fields (e.g., 'double').
  final String numberFormat;
}

/// Configuration for remote data source generation.
///
/// Controls HTTP client selection, Firebase integration, and other
/// remote data source features.
class RemoteDataSourceConfig {
  /// Creates a [RemoteDataSourceConfig] with the given settings.
  const RemoteDataSourceConfig({
    this.httpClient = HttpClientType.dio,
    this.useFirebaseAuth = false,
    this.useFirebaseFirestore = false,
    this.useFirebaseStorage = false,
    this.useGraphQL = false,
    this.useWebSockets = false,
    this.useSupabase = false,
    this.customDependencies = const [],
    this.baseUrl = '',
    this.timeout = 30000,
    this.enableLogging = true,
    this.enableRetry = true,
    this.maxRetries = 3,
  });

  /// Creates a [RemoteDataSourceConfig] from a map of configuration values.
  factory RemoteDataSourceConfig.fromMap(Map<dynamic, dynamic> map) {
    return RemoteDataSourceConfig(
      httpClient: _parseHttpClientType(map['http_client'] as String?),
      useFirebaseAuth: map['firebase_auth'] as bool? ?? false,
      useFirebaseFirestore: map['firebase_firestore'] as bool? ?? false,
      useFirebaseStorage: map['firebase_storage'] as bool? ?? false,
      useGraphQL: map['graphql'] as bool? ?? false,
      useWebSockets: map['websockets'] as bool? ?? false,
      useSupabase: map['supabase'] as bool? ?? false,
      customDependencies:
          (map['custom_dependencies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      baseUrl: map['base_url'] as String? ?? '',
      timeout: map['timeout'] as int? ?? 30000,
      enableLogging: map['enable_logging'] as bool? ?? true,
      enableRetry: map['enable_retry'] as bool? ?? true,
      maxRetries: map['max_retries'] as int? ?? 3,
    );
  }

  /// The HTTP client type to use.
  final HttpClientType httpClient;

  /// Whether to use Firebase Authentication.
  final bool useFirebaseAuth;

  /// Whether to use Firebase Firestore.
  final bool useFirebaseFirestore;

  /// Whether to use Firebase Storage.
  final bool useFirebaseStorage;

  /// Whether to use GraphQL.
  final bool useGraphQL;

  /// Whether to use WebSockets.
  final bool useWebSockets;

  /// Whether to use Supabase.
  final bool useSupabase;

  /// List of custom dependencies to include.
  final List<String> customDependencies;

  /// The base URL for API requests.
  final String baseUrl;

  /// Request timeout in milliseconds.
  final int timeout;

  /// Whether to enable logging.
  final bool enableLogging;

  /// Whether to enable automatic retry on failure.
  final bool enableRetry;

  /// Maximum number of retry attempts.
  final int maxRetries;

  static HttpClientType _parseHttpClientType(String? type) {
    switch (type?.toLowerCase()) {
      case 'dio':
        return HttpClientType.dio;
      case 'http':
        return HttpClientType.http;
      case 'chopper':
        return HttpClientType.chopper;
      case 'retrofit':
        return HttpClientType.retrofit;
      case 'custom':
        return HttpClientType.custom;
      default:
        return HttpClientType.dio;
    }
  }

  /// Gets the list of required imports based on the configuration.
  List<String> get requiredImports {
    final imports = <String>[];

    switch (httpClient) {
      case HttpClientType.dio:
        imports.add('package:dio/dio.dart');
      case HttpClientType.http:
        imports.add('package:http/http.dart');
      case HttpClientType.chopper:
        imports.add('package:chopper/chopper.dart');
      case HttpClientType.retrofit:
        imports.add('package:retrofit/retrofit.dart');
      case HttpClientType.custom:
        // Custom imports handled via customDependencies
        break;
    }

    if (useFirebaseAuth) {
      imports.add('package:firebase_auth/firebase_auth.dart');
    }

    if (useFirebaseFirestore) {
      imports.add('package:cloud_firestore/cloud_firestore.dart');
    }

    if (useFirebaseStorage) {
      imports.add('package:firebase_storage/firebase_storage.dart');
    }

    if (useGraphQL) {
      imports.add('package:graphql_flutter/graphql_flutter.dart');
    }

    if (useWebSockets) {
      imports.add('package:web_socket_channel/web_socket_channel.dart');
    }

    if (useSupabase) {
      imports.add('package:supabase_flutter/supabase_flutter.dart');
    }

    imports.addAll(customDependencies);

    return imports;
  }

  /// Gets the list of constructor dependencies based on the configuration.
  List<Dependency> get constructorDependencies {
    final dependencies = <Dependency>[];

    switch (httpClient) {
      case HttpClientType.dio:
        dependencies.add(const Dependency(type: 'Dio', name: 'dio'));
      case HttpClientType.http:
        dependencies.add(const Dependency(type: 'http.Client', name: 'client'));
      case HttpClientType.chopper:
        dependencies.add(
          const Dependency(type: 'ChopperClient', name: 'client'),
        );
      case HttpClientType.retrofit:
        dependencies.add(const Dependency(type: 'RestClient', name: 'client'));
      case HttpClientType.custom:
        dependencies.add(const Dependency(type: 'HttpClient', name: 'client'));
    }

    if (useFirebaseAuth) {
      dependencies.add(
        const Dependency(type: 'FirebaseAuth', name: 'firebaseAuth'),
      );
    }

    if (useFirebaseFirestore) {
      dependencies.add(
        const Dependency(type: 'FirebaseFirestore', name: 'firestore'),
      );
    }

    if (useFirebaseStorage) {
      dependencies.add(
        const Dependency(type: 'FirebaseStorage', name: 'storage'),
      );
    }

    if (useGraphQL) {
      dependencies.add(
        const Dependency(type: 'GraphQLClient', name: 'graphQLClient'),
      );
    }

    if (useWebSockets) {
      dependencies.add(
        const Dependency(type: 'WebSocketChannel', name: 'webSocketChannel'),
      );
    }

    if (useSupabase) {
      dependencies.add(
        const Dependency(type: 'SupabaseClient', name: 'supabaseClient'),
      );
    }

    return dependencies;
  }
}

/// HTTP client types supported by the generator.
enum HttpClientType {
  /// Dio HTTP client
  dio,

  /// Dart HTTP package
  http,

  /// Chopper HTTP client
  chopper,

  /// Retrofit HTTP client
  retrofit,

  /// Custom HTTP client
  custom,
}

/// Configuration for multi-file output mode.
///
/// When enabled, generated code is written to individual files
/// in the clean architecture structure instead of a single `.g.dart` file.
class MultiFileOutputConfig {
  /// Creates a [MultiFileOutputConfig] with the given settings.
  const MultiFileOutputConfig({
    this.enabled = false,
    this.autoCreateTargets = true,
  });

  /// Creates a [MultiFileOutputConfig] from a map of configuration values.
  factory MultiFileOutputConfig.fromMap(Map<dynamic, dynamic> map) {
    return MultiFileOutputConfig(
      enabled: map['enabled'] as bool? ?? false,
      autoCreateTargets: map['auto_create_targets'] as bool? ?? true,
    );
  }

  /// Whether multi-file output is enabled.
  final bool enabled;

  /// Whether to automatically create target files if they don't exist.
  final bool autoCreateTargets;

  /// Converts this configuration to a map.
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'auto_create_targets': autoCreateTargets,
    };
  }
}

/// Configuration for feature scaffolding.
///
/// When enabled, allows pre-generation of feature files when creating
/// a new feature via the CLI.
class FeatureScaffoldingConfig {
  /// Creates a [FeatureScaffoldingConfig] with the given settings.
  const FeatureScaffoldingConfig({
    this.rootName = 'feature',
    this.enabled = false,
    this.features = const {},
  });

  /// Creates a [FeatureScaffoldingConfig] from a map of configuration values.
  factory FeatureScaffoldingConfig.fromMap(Map<dynamic, dynamic> map) {
    final featuresMap = map['features'] as Map<dynamic, dynamic>? ?? {};
    final features = <String, FeatureDefinition>{};

    for (final entry in featuresMap.entries) {
      final featureName = entry.key as String;
      final featureData = entry.value as Map<dynamic, dynamic>? ?? {};
      features[featureName] = FeatureDefinition.fromMap(featureData);
    }

    return FeatureScaffoldingConfig(
      rootName: map['root_name'] as String? ?? 'feature',
      enabled: map['enabled'] as bool? ?? false,
      features: features,
    );
  }

  /// The root name for feature scaffolding.
  final String rootName;

  /// Whether feature scaffolding is enabled.
  final bool enabled;

  /// Map of feature names to their definitions.
  final Map<String, FeatureDefinition> features;

  /// Converts this configuration to a map.
  Map<String, dynamic> toMap() {
    return {
      'root_name': rootName,
      'enabled': enabled,
      'features': features.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  /// Checks if a feature is defined.
  bool hasFeature(String featureName) => features.containsKey(featureName);

  /// Gets the definition for a specific feature.
  FeatureDefinition? getFeature(String featureName) => features[featureName];
}

/// Definition of a feature for scaffolding.
///
/// Contains the methods and optional data file name for a feature.
class FeatureDefinition {
  /// Creates a [FeatureDefinition] with the given methods and data file name.
  const FeatureDefinition({
    this.methods = const [],
    this.entities = const [],
    this.dataFileName,
  });

  /// Creates a [FeatureDefinition] from a map of configuration values.
  factory FeatureDefinition.fromMap(Map<dynamic, dynamic> map) {
    final methodsList = map['methods'] as List<dynamic>? ?? [];
    final entitiesList = map['entities'] as List<dynamic>? ?? [];

    return FeatureDefinition(
      methods: methodsList.map((e) => e.toString()).toList(),
      entities: entitiesList.map((e) => e.toString()).toList(),
      dataFileName: map['data_file_name'] as String?,
    );
  }

  /// List of method names for this feature.
  final List<String> methods;

  /// List of entity names for this feature.
  final List<String> entities;

  /// Optional custom data file name.
  final String? dataFileName;

  /// Converts this feature definition to a map.
  Map<String, dynamic> toMap() {
    return {
      'methods': methods,
      'entities': entities,
      if (dataFileName != null) 'data_file_name': dataFileName,
    };
  }

  @override
  String toString() {
    return 'FeatureDefinition{'
        'methods: $methods, '
        'entities: $entities, '
        'dataFileName: $dataFileName'
        '}';
  }
}

/// Represents a dependency with a type and a name.
///
/// Used for defining dependencies in the configuration.
class Dependency {
  /// Creates a [Dependency] with the given type and name.
  const Dependency({required this.type, required this.name});

  /// The type of the dependency.
  final String type;

  /// The name of the dependency.
  final String name;

  /// The private name of the dependency.
  String get privatisedName => '_$name';
}

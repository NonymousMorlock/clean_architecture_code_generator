# Generators

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

Clean Architecture code generators for Dart/Flutter projects.

## Features

This package provides a comprehensive set of code generators for implementing Clean Architecture in Dart/Flutter projects:

### Core Generators
- **Entity Generator** - Generate domain entities with immutable properties
- **Model Generator** - Generate data models with JSON serialization
- **Repository Generator** - Generate repository interfaces
- **Use Case Generator** - Generate use case classes following the single responsibility principle

### Data Layer Generators
- **Remote Data Source Generator** - Generate remote data source implementations
- **Local Data Source Generator** - Generate local data source implementations
- **Repository Implementation Generator** - Generate repository implementations

### Presentation Layer Generators
- **Interface Adapter Generator** - Generate Cubit/Bloc interface adapter classes

### Testing Generators
- **Model Test Generator** - Generate comprehensive model tests
- **Use Case Test Generator** - Generate use case tests
- **Repository Implementation Test Generator** - Generate repository implementation tests

### Additional Generators
- **Injection Generator** - Generate dependency injection containers

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  annotations:
    path: ../annotations/

dev_dependencies:
  generators:
    path: ../generators/
  build_runner: ^2.4.0
```

## Usage

### 1. Annotate Your Classes

```dart
import 'package:annotations/annotations.dart';

@entityGen
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}
```

### 2. Configure build.yaml

Create a `build.yaml` file in your project root:

```yaml
targets:
  $default:
    builders:
      generators|generators:
        enabled: true
        generate_for:
          include:
            - "lib/**"

builders:
  generators|generators:
    target: ":generators"
    import: "package:generators/generators.dart"
    builder_factories:
      - generateEntityClass
      - generateModelClass
      - generateUsecases
      - generateRepository
      - generateRepoImpl
      - generateRemoteDataSrc
      - generateLocalDataSrc
      - generateAdapter
      - generateModelTest
      - generateUsecasesTest
      - generateRepoImplTest
      - generateInjectionContainer
    build_extensions: { ".dart": [ ".g.dart" ] }
    auto_apply: dependents
    build_to: source
    applies_builders: [ "source_gen|combining_builder" ]
```

### 3. Run Code Generation

```bash
dart run build_runner build
```

Or for continuous generation:

```bash
dart run build_runner watch
```

## Available Annotations

| Annotation          | Purpose                    | Generator                |
|---------------------|----------------------------|--------------------------|
| `@entityGen`        | Domain entities            | `EntityGenerator`        |
| `@modelGen`         | Data models                | `ModelGenerator`         |
| `@repoGen`          | Repository interfaces      | `RepoGenerator`          |
| `@usecaseGen`       | Use cases                  | `UsecaseGenerator`       |
| `@remoteDataSrcGen` | Remote data sources        | `RemoteDataSrcGenerator` |
| `@localDataSrcGen`  | Local data sources         | `LocalDataSrcGenerator`  |
| `@repoImplGen`      | Repository implementations | `RepoImplGenerator`      |
| `@adapterGen`       | Interface Adapter          | `AdapterGenerator`       |
| `@injectionGen`     | DI containers              | `InjectionGenerator`     |

## Advanced Features

### Multi-File Output

Instead of generating all code into `.g.dart` files, you can configure the generators to write to individual files based on your clean architecture structure.

Configure via `clean_arch_config.yaml`:

```yaml
multi_file_output:
  enabled: true
  repository_path: 'lib/features/{feature}/domain/repository'
  usecase_path: 'lib/features/{feature}/domain/usecases'
  data_source_path: 'lib/features/{feature}/data/datasources'
  repository_impl_path: 'lib/features/{feature}/data/repositories'
```

### Feature Scaffolding

Pre-generate feature files when creating new features:

```yaml
feature_scaffolding:
  enabled: true
  generate_on_create: true
  features:
    auth:
      methods:
        - login
        - register
        - logout
```

## Package Structure

```
lib/
├── core/
│   ├── config/          # Configuration parsing
│   ├── services/        # Core services (file writing, utilities)
│   └── utils/           # Utility functions
├── src/
│   ├── generators/      # All generator implementations
│   ├── models/          # Data models for code generation
│   └── visitors/        # AST visitors
└── generators.dart      # Main export file
```

## Development

### Running Tests

```bash
dart test
```

### Running Linter

```bash
dart analyze
```

### Formatting Code

```bash
dart format .
```

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [annotations](../annotations/) - Annotations used by these generators
- [cli](../cli/) - Command-line interface for the code generator

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis

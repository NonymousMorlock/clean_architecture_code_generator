# Clean Architecture Code Generator

A powerful Flutter code generator that creates clean architecture boilerplate following industry best practices. Generate entities, models, repositories, use cases, remote data sources, dependency injection, and state management code automatically.

## 🏗️ Core Philosophy: Source-to-Source Scaffolding

Unlike common Dart generators (like `freezed` or `json_serializable`) which focus on **Derived Generation** (creating hidden functional artifacts you never touch), this tool is a **Source-to-Source Scaffolding Factory**.

We believe the value of Clean Architecture is in the separation of concerns, not the typing of boilerplate. This tool handles the typing so you can focus on the logic, and it does so without taking control away from you.

### How it differs:
*   **Developer Ownership**: The generator produces actual human-readable Dart source files. Once generated, **you own the code**. You can (and should) modify, refactor, and commit these files to your repository.
*   **Respectful Updates**: The generator is a collaborator, not a dictator. It uses a **Smart Merge Engine** to ensure that when you update your blueprints and regenerate, your manual customizations are preserved.
*   **Blueprints (`TBG` files)**: Classes ending in `TBG` (To Be Generated) are temporary blueprints. They serve as instructions for the factory. Once your feature is scaffolded, these files are no longer needed for your app to run. You can delete them or keep them ignored in version control.
*   **Zero Production Bloat**: Since the generated code is standard Dart, both the `annotations` and `generators` packages are strictly `dev_dependencies`. Your final application binary contains zero overhead from this tool.

---

## 🚀 Features

- **Complete Clean Architecture**: Generate all layers (Domain, Data, Presentation)
- **Entity & Model Generation**: Create domain entities and data models with JSON serialization
- **Repository Pattern**: Generate abstract repositories and implementations
- **Use Cases**: Create use cases following the single responsibility principle
- **Data Sources**: Generate robust remote (HTTP/API) data sources
- **Interface Adapter**: Generate Cubit/BLoC with comprehensive state management
- **Dependency Injection**: Create GetIt service locator patterns automatically
- **CLI Tool**: Command-line interface for easy project management
- **Configuration**: YAML-based configuration for customization
- **Test Generation**: Generate unit tests for all components
- **Multi-File Output**: Write generated code directly to feature files instead of .g.dart files
- **Feature Scaffolding**: Pre-generate feature structure from YAML configuration
- **Smart 3-Way Merge**: Regenerate features without losing your manual code customizations.

## 📋 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [CLI Usage](#-cli-usage)
- [Annotations Reference](#-annotations-reference)
- [Generated Code Structure](#-generated-code-structure)
- [Best Practices](#-best-practices)
- [Configuration](#-configuration)

## 🛠️ Installation

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Git (Recommended for high-precision 3-way merging)

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/clean_architecture_code_generator.git
   cd clean_architecture_code_generator
   ```

2. **Install CLI globally:**
   ```bash
   cd cli
   dart pub global activate --source path .
   ```
   *Note: After activation, you can run `clean_arch_cli` directly from any project directory.*
   

## 🚀 Quick Start

### Using the Factory in your project

1. **Initialize the tool in your target project:**
   ```bash
   cd <your_project_directory>
   clean_arch_cli init
   ```
   **Options:**
   - `--project-name, -n`: Name of the Flutter project (required)
   - `--output, -o`: Output directory (default: current directory)
   - `--with-examples`: Include example models and repositories (default: true)

   This automatically:
   * Adds dependencies to your pubspec.yaml
       Note: All tooling is kept in `dev_dependencies`.
       ```yaml
       dev_dependencies:
         build_runner: any
         generators:
           git:
             url: https://github.com/NonymousMorlock/clean_architecture_code_generator.git
             path: generators
         mocktail: any
       ```
   * Generates the `clean_arch_config.yaml` file.
   * Generates a sample directory in lib/src/sample/tbg/ with sample TBG files. See [Annotations Reference](#-annotations-reference) for more details

2. **Generate your source code:**
    ```bash
    clean_arch_cli generate [options]
    ```

    **Options:**
   - `--path, -p`: Path to Flutter project (default: current directory)
   - `--watch, -w`: Watch for changes and regenerate automatically
   - `--delete-conflicting-outputs`: Delete conflicting outputs before generation

---

## 📝 Annotations Reference

### Entity & Model Generation

The generator uses the parameter names in your `TBG` class as the keys for JSON serialization. If your API uses specific naming conventions (like snake_case or PascalCase), you should declare the properties in your annotated class using that exact casing.

```dart
@modelTestGen
@modelGen
@entityGen
class UserTBG {
  const UserTBG({
    required String id,
    required String Email,           // Maps to 'Email' in JSON
    required String Name,            // Maps to 'Name' in JSON
    required Address PrimaryAddress, // Maps to 'PrimaryAddress' in JSON
    required List<int> favoriteItemIds,
    List<Address>? addresses,
    DateTime? created_at,            // Maps to 'created_at' in JSON
  });
}
```

Internal fields in the generated Entity and Model will automatically be converted to `camelCase` for idiomatic Dart usage, while preserving the original casing in `fromMap` and `toMap` for API compatibility.

### Repository & Use Case Generation

```dart
@repoGen          // Generates modifiable abstract repository
@usecaseGen       // Generates modifiable use cases
@repoImplGen      // Generates modifiable repository implementation
@remoteSrcGen     // Generates modifiable remote data source
@adapterGen       // Generates modifiable interface adapter
@usecaseTestGen   // Generates modifiable use case tests
@repoImplTestGen  // Generates modifiable repository tests
@remoteSrcTestGen // Generates modifiable remote data source tests
class AuthRepoTBG {
  external ResultFuture<User> login({required String email, required String password});
  external ResultFuture<User> register({required String email, required String password});
  external ResultFuture<void> logout();
  external ResultFuture<User> getCurrentUser();
}
```

#### Signature Optimization: Named over Positional

To ensure a robust and idiomatic API, the generator automatically converts **Optional Positional** parameters defined in your `TBG` blueprints into **Optional Named** parameters in the generated code.

**Why we do this:**
*   **Decoupling from Order**: You can pass optional arguments in any order without providing `null` for preceding ones.
*   **Clean Architecture Consistency**: It simplifies the mapping between `UseCase` parameter objects and repository methods.
*   **Standardization**: Ensures the contract across Domain, Data, and Remote layers remains consistent and easy to maintain.

**Example:**
```dart
// Your Blueprint (AuthRepoTBG)
external ResultFuture<void> searchUser(String query, [int? limit]);

// The Scaffolded Result (AuthRepository)
ResultFuture<void> searchUser(String query, {int? limit});
```

---

## 🏗️ Generated Code Structure

### The Scaffolding Result

When you annotate a `UserRepoTBG` class, the generator scaffolds actual files that follow Clean Architecture conventions. Unlike other generators, you won't find the implementation logic trapped in `.g.dart` files; it will be in your `lib/` directory, ready for you to add your business logic.

```
lib/src/user/
├── data/
│   ├── datasources/
│   │   └── user_remote_data_source.dart      # Modifiable HTTP/API implementation
│   ├── models/
│   │   └── user_model.dart                   # Modifiable JSON serialization
│   └── repositories/
│       └── user_repository_impl.dart         # Modifiable Repository implementation
├── domain/
│   ├── entities/
│   │   └── user.dart                         # Modifiable Domain entity
│   ├── repositories/
│   │   └── user_repository.dart              # Modifiable Abstract repository
│   └── usecases/
│       ├── login.dart                        # Modifiable Use case
│       └── register.dart 
├── presentation/
│   └── adapter/
│       ├── user_adapter.dart                   # Modifiable Adapter
│       └── user_state.dart                     # Modifiable Adapter state
...tests as well. y'know
```

---

## 🎯 Best Practices

### 1. The `TBG` Lifecycle
Think of `TBG` files as **scaffolding instructions**. 
1. **Define**: Create the `TBG` class.
2. **Scaffold**: Run `generate`.
3. **Own**: The generated files are standard Dart. **You own them.** Modify them or add business logic.
4. **Evolve**: Need a new field? Update the `TBG` and run `generate` again. The generator will merge the new field while keeping your existing logic safe.

### 2. Smart Merging & Conflict Resolution
If you and the generator modify the **exact same line**, the tool will inject standard Git conflict markers:

```dart
<<<<<<< MINE (User Changes)
'email': map['Email'], // Your manual fix
=======
'email': map['email_address'], // New generator update
>>>>>>> THEIRS (Generator Output)
```

**To resolve:** Simply use Android Studio or VS Code's built-in merge tools to pick the version you want. This ensures you are always the final authority on your codebase. If the IDE doesn't show merge options, you can manually edit the file to resolve the conflicts.

> **Technical Note:** Our engine uses a hybrid approach for conflict resolution. If Git is detected in your environment, it leverages the native 3-way merge algorithm (`git merge-file`) for granular, character-level precision. If not, it falls back to a strict line-based safe merge to ensure your customizations are never lost.

### 3. Naming Conventions
*   **Blueprints**: Always end with `TBG` (e.g., `UserTBG`, `AuthRepoTBG`).
*   **API Keys**: Use mixed casing in constructor parameters if your API keys aren't camelCase.

### 4. Test Data & Fixtures
When generating model tests, the generator creates JSON fixtures. Note that **custom types (nested models)** are skipped in the generated fixture file to keep it manageable. However, the generated test code automatically "hydrates" these fields in the `setUpAll` block by injecting `CustomType.empty().toMap()`, ensuring your serialization tests remain robust.

---

## ⚙️ Configuration

Create a `clean_arch_config.yaml` file in your project root to customize your factory:

```yaml
# Multi-file output is highly recommended for the Scaffolding workflow
multi_file_output:
  enabled: true                  # Recommended: Write to actual feature files
  auto_create_targets: true      # Auto-create missing files
```

---

**Happy coding with Clean Architecture! 🚀**

For more examples and updates, visit our [GitHub repository](https://github.com/NonymousMorlock/clean_architecture_code_generator).

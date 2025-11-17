# Clean Architecture Code Generator

A powerful Flutter code generator that creates clean architecture boilerplate following industry best practices. Generate entities, models, repositories, use cases, data sources, dependency injection, and state management code automatically.

## 🚀 Features

- **Complete Clean Architecture**: Generate all layers (Domain, Data, Presentation)
- **Entity & Model Generation**: Create domain entities and data models with JSON serialization
- **Repository Pattern**: Generate abstract repositories and implementations
- **Use Cases**: Create use cases following the single responsibility principle
- **Data Sources**: Generate both remote (HTTP/API) and local (SharedPreferences) data sources
- **State Management**: Generate Cubit/BLoC with comprehensive state management
- **Dependency Injection**: Create GetIt service locator patterns automatically
- **CLI Tool**: Command-line interface for easy project management
- **Configuration**: YAML-based configuration for customization
- **Test Generation**: Generate unit tests for all components
- **Multi-File Output**: Write generated code directly to feature files instead of .g.dart files
- **Feature Scaffolding**: Pre-generate feature structure from YAML configuration

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI Usage](#cli-usage)
- [Annotations Reference](#annotations-reference)
- [Generated Code Structure](#generated-code-structure)
- [Configuration](#configuration)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🛠️ Installation

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/clean_architecture_code_generator.git
   cd clean_architecture_code_generator
   ```

2. **Install dependencies for all packages:**
   ```bash
   # Install CLI dependencies
   cd cli && flutter pub get && cd ..
   
   # Install generator dependencies
   cd generators && flutter pub get && cd ..
   
   # Install annotation dependencies
   cd annotations && flutter pub get && cd ..
   ```

3. **Install CLI globally (optional):**
   ```bash
   cd cli
   dart pub global activate --source path .
   ```

## 🚀 Quick Start

### Option 1: Using CLI (Recommended)

1. **Create a new project:**
   ```bash
   dart run clean_arch_cli:clean_arch_cli init --project-name my_app
   cd my_app
   ```

2. **Add the generator dependencies to your `pubspec.yaml`:**
   ```yaml
   dependencies:
     # Your existing dependencies
     equatable: ^2.0.5
     dartz: ^0.10.1
     get_it: ^7.6.4
     shared_preferences: ^2.2.2
     dio: ^5.3.2
     bloc: ^8.1.2
     flutter_bloc: ^8.1.3

   dev_dependencies:
     # Your existing dev dependencies
     build_runner: ^2.4.7
     annotations:
       path: ../annotations
     generators:
       path: ../generators
   ```

3. **Create your first feature:**
   ```bash
   dart run clean_arch_cli:clean_arch_cli create --type feature --name authentication
   ```

### Option 2: Manual Setup

1. **Create a new Flutter project:**
   ```bash
   flutter create my_app && cd my_app
   ```

2. **Add dependencies** (same as above)

3. **Create clean architecture folder structure:**
   ```
   lib/
   ├── core/
   │   ├── constants/
   │   ├── errors/
   │   ├── network/
   │   ├── usecases/
   │   └── utils/
   ├── features/
   │   └── authentication/
   │       ├── data/
   │       │   ├── datasources/
   │       │   ├── models/
   │       │   └── repositories/
   │       ├── domain/
   │       │   ├── entities/
   │       │   ├── repositories/
   │       │   └── usecases/
   │       └── presentation/
   │           ├── bloc/
   │           ├── pages/
   │           └── widgets/
   └── injection_container/
   ```

## 🖥️ CLI Usage

The CLI tool provides several commands to help you manage your clean architecture project:

### Initialize Project
```bash
dart run clean_arch_cli:clean_arch_cli init --project-name my_app [options]
```

**Options:**
- `--project-name, -n`: Name of the Flutter project (required)
- `--output, -o`: Output directory (default: current directory)
- `--with-examples`: Include example models and repositories (default: true)

### Generate Code
```bash
dart run clean_arch_cli:clean_arch_cli generate [options]
```

**Options:**
- `--path, -p`: Path to Flutter project (default: current directory)
- `--watch, -w`: Watch for changes and regenerate automatically
- `--delete-conflicting-outputs`: Delete conflicting outputs before generation

### Create Components
```bash
dart run clean_arch_cli:clean_arch_cli create --type <type> --name <name> [options]
```

**Types:**
- `feature`: Create a complete feature with all folders
- `entity`: Create a domain entity
- `repository`: Create a repository interface
- `usecase`: Create a use case
- `cubit`: Create a cubit with states

**Options:**
- `--type, -t`: Type of component (required)
- `--name, -n`: Name of the component (required)
- `--feature, -f`: Feature name (required for non-feature components)
- `--path, -p`: Project path (default: current directory)

### CLI Examples

```bash
# Create a new project
dart run clean_arch_cli:clean_arch_cli init -n my_ecommerce_app

# Create a new feature
dart run clean_arch_cli:clean_arch_cli create -t feature -n products

# Create an entity
dart run clean_arch_cli:clean_arch_cli create -t entity -n product -f products

# Create a repository
dart run clean_arch_cli:clean_arch_cli create -t repository -n product -f products

# Generate code with watch mode
dart run clean_arch_cli:clean_arch_cli generate --watch
```

## 📝 Annotations Reference

### Entity & Model Generation

```dart
@entityGen  // Generates domain entity
@modelGen   // Generates data model with JSON serialization
class UserTBG {
  @required
  final String id;
  @required
  final String email;
  final String? profileImage;
  @required
  final DateTime createdAt;
}
```

### Repository & Use Case Generation

```dart
@repoGen        // Generates abstract repository
@usecaseGen     // Generates use cases for each method
@repoImplGen    // Generates repository implementation
@remoteSrcGen   // Generates remote data source (HTTP/API)
@localSrcGen    // Generates local data source (SharedPreferences)
@injectionGen   // Generates dependency injection setup
class AuthRepoTBG {
  external ResultFuture<User> login({required String email, required String password});
  external ResultFuture<User> register({required String email, required String password});
  external ResultFuture<void> logout();
  external ResultFuture<User> getCurrentUser();
}
```

### State Management Generation

```dart
@cubitGen  // Generates Cubit with states
class AuthCubitTBG {
  // This will generate a cubit based on the repository methods
  // with proper state management including loading, success, and error states
}
```

### Test Generation

```dart
@modelTestGen      // Generates model tests
@usecaseTestGen    // Generates use case tests
@repoImplTestGen   // Generates repository implementation tests
@remoteSrcTestGen  // Generates remote data source tests
@localSrcTestGen   // Generates local data source tests
```

## 🏗️ Generated Code Structure

### Example: User Feature

When you annotate a `UserRepoTBG` class with all annotations, the generator creates:

```
lib/features/user/
├── data/
│   ├── datasources/
│   │   ├── user_remote_data_source.dart      # HTTP/API calls
│   │   └── user_local_data_source.dart       # SharedPreferences
│   ├── models/
│   │   └── user_model.dart                   # JSON serialization
│   └── repositories/
│       └── user_repository_impl.dart         # Repository implementation
├── domain/
│   ├── entities/
│   │   └── user.dart                         # Domain entity
│   ├── repositories/
│   │   └── user_repository.dart              # Abstract repository
│   └── usecases/
│       ├── login.dart                        # Login use case
│       ├── register.dart                     # Register use case
│       └── get_current_user.dart            # Get user use case
└── presentation/
    └── bloc/
        ├── user_cubit.dart                   # State management
        └── user_state.dart                  # State definitions
```

### Generated Dependency Injection

```dart
// injection_container.dart
Future<void> _initUser() async {
  sl
    ..registerFactory(() {
      return UserCubit(
        login: sl(),
        register: sl(),
        getCurrentUser: sl(),
      );
    })
    ..registerLazySingleton(() => Login(sl()))
    ..registerLazySingleton(() => Register(sl()))
    ..registerLazySingleton(() => GetCurrentUser(sl()))
    ..registerLazySingleton<UserRepo>(() => UserRepoImpl(sl(), sl()))
    ..registerLazySingleton<UserRemoteDataSrc>(() => UserRemoteDataSrcImpl(sl()))
    ..registerLazySingleton<UserLocalDataSrc>(() => UserLocalDataSrcImpl(sl()));
}
```

## ⚙️ Configuration

Create a `clean_arch_config.yaml` file in your project root to customize generation:

```yaml
# Clean Architecture Code Generator Configuration

# Application configuration
app_name: "your_app"  # Change this to your actual app name (used for import paths)

# Output directory for generated files
output_path: lib

# Naming convention: camel_case, snake_case, pascal_case
naming_convention: camel_case

# Generation options
generate_tests: true
generate_docs: false

# Custom imports added to generated files
custom_imports:
  - "import 'dart:convert';"
  - "import 'package:dartz/dartz.dart';"
  - "import 'package:equatable/equatable.dart';"

# Feature structure
feature_structure:
  data_path: data
  domain_path: domain
  presentation_path: presentation
  use_subfolders: true

# Dependency injection
dependency_injection:
  service_locator: get_it
  generate_injection_container: true
  container_name: injection_container

# State management
state_management:
  type: cubit  # Options: cubit, bloc
  generate_states: true
  error_handling: true

# Remote data source configuration
remote_data_source:
  # HTTP Client configuration
  http_client: "dio"              # Options: dio, http, chopper, retrofit, custom
  base_url: "https://api.example.com"
  timeout: 30000                  # Timeout in milliseconds
  enable_logging: true
  enable_retry: true
  max_retries: 3

  # Service integrations
  firebase_auth: false            # Use Firebase Authentication
  firebase_firestore: false      # Use Cloud Firestore
  firebase_storage: false        # Use Firebase Storage
  graphql: false                  # Use GraphQL client
  websockets: false               # Use WebSocket connections
  supabase: false                 # Use Supabase client

  # Custom dependencies (for packages not covered above)
  custom_dependencies:
    - "package:custom_http_client/custom_http_client.dart"
    - "package:analytics/analytics.dart"
```

### 🎯 Remote Data Source Configuration Benefits

The remote data source generator now uses **YAML configuration** instead of terminal prompts, providing:

- **🚀 Non-Interactive Builds**: No more terminal prompts during code generation
- **🔄 Consistent Builds**: Same configuration produces identical results across environments
- **⚙️ CI/CD Friendly**: Perfect for automated build pipelines
- **📝 Version Controlled**: Configuration is part of your codebase
- **🎛️ Declarative**: Clear, readable dependency specification

**Before (Terminal Prompts):**
```
REMOTE DATA SOURCE DEPENDENCIES FOR UserRemoteDataSrc
does it use FirebaseAuth? (yes/no): yes
does it use Dio? (yes/no): yes
```

**After (YAML Configuration):**
```yaml
remote_data_source:
  http_client: "dio"
  firebase_auth: true
```

## 📚 Examples

### Complete Feature Example

1. **Create the entity:**
   ```dart
   // lib/features/products/domain/entities/product.dart
   import 'package:annotations/annotations.dart';

   @entityGen
   @modelGen
   class ProductTBG {
     @required
     final String id;
     @required
     final String name;
     @required
     final String description;
     @required
     final double price;
     final String? imageUrl;
     @required
     final String categoryId;
     @required
     final DateTime createdAt;
     @required
     final DateTime updatedAt;
   }
   ```

2. **Create the repository:**
   ```dart
   // lib/features/products/domain/repositories/product_repository.dart
   import 'package:annotations/annotations.dart';
   import '../../../../core/typedefs.dart';
   import '../entities/product.dart';

   @repoGen
   @usecaseGen
   @repoImplGen
   @remoteSrcGen
   @localSrcGen
   @injectionGen
   @cubitGen
   class ProductRepoTBG {
     external ResultFuture<List<Product>> getProducts({int? page, int? limit});
     external ResultFuture<Product> getProductById(String id);
     external ResultFuture<Product> createProduct(Product product);
     external ResultFuture<Product> updateProduct(Product product);
     external ResultFuture<void> deleteProduct(String id);
     external ResultFuture<List<Product>> searchProducts(String query);
   }
   ```

3. **Generate the code:**
   ```bash
   dart run clean_arch_cli:clean_arch_cli generate
   ```

4. **Use in your app:**
   ```dart
   // main.dart
   import 'injection_container.dart' as di;

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await di.init();
     runApp(MyApp());
   }

   // In your widget
   BlocProvider(
     create: (context) => di.sl<ProductCubit>(),
     child: ProductListPage(),
   )
   ```

## 🎯 Best Practices

### 1. Naming Conventions

- **Entities**: End with `TBG` (To Be Generated)
  ```dart
  class UserTBG { }  // Generates: User entity, UserModel
  ```

- **Repositories**: End with `RepoTBG`
  ```dart
  class AuthRepoTBG { }  // Generates: AuthRepo, AuthRepoImpl
  ```

- **Use descriptive method names**: The generator creates use case names from method names
  ```dart
  external ResultFuture<User> getCurrentUser();  // Generates: GetCurrentUser use case
  ```

### 2. Required Fields

Use `@required` annotation for mandatory fields:
```dart
class UserTBG {
  @required
  final String email;  // Will be required in constructors
  final String? bio;   // Optional field
}
```

### 3. Return Types

- Use `ResultFuture<T>` for async operations
- Use `ResultStream<T>` for streams
- Use proper generic types for lists: `ResultFuture<List<Product>>`

### 4. Method Parameters

- Single parameter: Generates simple use case
- Multiple parameters: Generates params class automatically
- Use named parameters for better API design

### 5. Error Handling

The generator creates comprehensive error handling:
```dart
// Generated cubit method
Future<void> getProducts() async {
  emit(const ProductLoading());
  
  final result = await _getProducts();
  
  result.fold(
    (failure) => emit(ProductError.fromFailure(failure)),
    (products) => emit(ProductsLoaded(products)),
  );
}
```

## 🎯 Multi-File Output Mode

### Overview

By default, the generator writes all code to `.g.dart` files. With multi-file output mode, generated code is written directly to your feature files, making the codebase cleaner and easier to navigate.

### Configuration

Enable multi-file output in `clean_arch_config.yaml`:

```yaml
multi_file_output:
  enabled: true                  # Write to actual feature files
  auto_create_targets: true      # Auto-create missing files
```

### How It Works

When enabled, the generator:

1. **Repository Interface** → `lib/features/{feature}/domain/repositories/{feature}_repository.dart`
2. **Use Cases** → `lib/features/{feature}/domain/usecases/{method_name}.dart` (one file per method)
3. **Remote Data Source** → `lib/features/{feature}/data/datasources/{feature}_remote_data_src.dart`
4. **Repository Implementation** → `lib/features/{feature}/data/repositories/{feature}_repository_impl.dart`
5. **Tests** → `test/features/{feature}/...` (mirrors the lib structure)

### Benefits

- **Cleaner Structure**: No more monolithic `.g.dart` files
- **Better Navigation**: Each component in its own file
- **Easier Review**: Smaller, focused files for code reviews
- **Standard Layout**: Follows clean architecture conventions

### Auto-Creation

If `auto_create_targets: true`, missing files are created automatically during generation. If `false`, generation fails if target files don't exist.

## 🏗️ Feature Scaffolding

### Overview

Pre-generate complete feature structures from YAML configuration when running `create -t feature`.

### Configuration

Enable and configure features in `clean_arch_config.yaml`:

```yaml
feature_scaffolding:
  enabled: true
  features:
    auth:
      methods:
        - register
        - login
        - logout
        - verify_token
      data_file_name: auth  # Optional: override default naming
    
    user:
      methods:
        - get_profile
        - update_profile
        - delete_account
```

### Usage

```bash
# Create a feature with scaffolding
dart run clean_arch_cli:clean_arch_cli create --type feature --name auth
```

If `auth` is defined in the config with `feature_scaffolding.enabled: true`, the CLI will:

1. Create the standard directory structure
2. Generate repository file with all methods
3. Create empty usecase files (one per method)
4. Create empty data source files
5. Create empty repository implementation files

Then run the generator to populate the files:

```bash
dart run clean_arch_cli:clean_arch_cli generate
```

### Combined Workflow

When both features are enabled:

1. **Create Feature**: `create -t feature --name auth` → scaffolds structure from config
2. **Generate Code**: `generate` → populates files with generated code (multi-file mode writes to actual files)
3. **Implement**: Fill in TODO sections in data sources and add business logic

### Benefits

- **Rapid Setup**: Feature structure created instantly
- **Consistency**: All features follow the same pattern
- **Configuration-Driven**: Define features once, create many times
- **No Manual File Creation**: Everything automated

## 🐛 Troubleshooting

### Common Issues

1. **"No pubspec.yaml found"**
   - Ensure you're in a Flutter project directory
   - Run the CLI from the project root

2. **"Build failed"**
   - Run `flutter clean && flutter pub get`
   - Check for syntax errors in your annotated classes
   - Ensure all required dependencies are in pubspec.yaml

3. **"Generator not found"**
   - Verify the generators package is in your dev_dependencies
   - Run `flutter packages get`

4. **"Import errors in generated files"**
   - Check your custom imports in the config file
   - Ensure all required packages are added to pubspec.yaml

5. **"Could not write to file" (Multi-File Mode)**
   - Ensure the feature directory structure exists
   - Check file permissions
   - Verify `auto_create_targets` is enabled if files don't exist

### Generated Files Not Updating

1. **Clean and regenerate:**
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Check file names:**
   - Ensure your classes end with `TBG`
   - Verify annotations are properly imported

3. **Watch mode issues:**
   ```bash
   # Stop watch mode and restart
   dart run clean_arch_cli:clean_arch_cli generate --watch
   ```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Happy coding with Clean Architecture! 🚀**

For more examples and updates, visit our [GitHub repository](https://github.com/your-username/clean_architecture_code_generator).
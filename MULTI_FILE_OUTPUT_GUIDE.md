# Multi-File Output & Feature Scaffolding Guide

## Overview

This guide explains the new multi-file output mode and feature scaffolding capabilities added to the Clean Architecture Code Generator.

## Features Implemented

### 1. Multi-File Output Mode

Instead of writing all generated code to a single `.g.dart` file, the generator can now write code directly to individual feature files following clean architecture conventions.

#### Configuration

Add to `clean_arch_config.yaml`:

```yaml
multi_file_output:
  enabled: false                  # Set to true to enable
  auto_create_targets: true       # Auto-create missing files
```

#### File Mapping

When enabled, generated code is written to:

| Generated Code | Target File |
|---------------|-------------|
| Repository Interface | `lib/features/{feature}/domain/repositories/{feature}_repository.dart` |
| Use Cases | `lib/features/{feature}/domain/usecases/{method_name}.dart` (one per method) |
| Remote Data Source | `lib/features/{feature}/data/datasources/{feature}_remote_data_src.dart` |
| Repository Implementation | `lib/features/{feature}/data/repositories/{feature}_repository_impl.dart` |
| Repository Tests | `test/features/{feature}/data/repositories/{feature}_repository_impl_test.dart` |

#### Benefits

- **Cleaner codebase**: No monolithic `.g.dart` files
- **Better navigation**: Each component in its own file
- **Standard structure**: Follows clean architecture conventions
- **Easier code review**: Smaller, focused files

### 2. Feature Scaffolding

Pre-generate complete feature structures from YAML configuration when creating features.

#### Configuration

Add to `clean_arch_config.yaml`:

```yaml
feature_scaffolding:
  enabled: false                  # Set to true to enable
  features:
    auth:
      methods:
        - register
        - login
        - logout
        - verify_token
      data_file_name: auth        # Optional: override default naming
    
    user:
      methods:
        - get_profile
        - update_profile
        - delete_account
```

#### Usage

```bash
# Create a feature
dart run clean_arch_cli:clean_arch_cli create --type feature --name auth

# If auth is defined in config with scaffolding enabled:
# - Creates directory structure
# - Generates repository file with all methods
# - Creates empty usecase files (one per method)
# - Creates empty data source files
# - Creates empty repository implementation files

# Then run the generator to populate the files
dart run clean_arch_cli:clean_arch_cli generate
```

#### Benefits

- **Rapid setup**: Complete feature structure created instantly
- **Consistency**: All features follow the same pattern
- **Configuration-driven**: Define once, create many times
- **No manual file creation**: Everything automated

## Combined Workflow

When both features are enabled, you get a powerful workflow:

1. **Define Feature in Config**:
   ```yaml
   feature_scaffolding:
     enabled: true
     features:
       products:
         methods:
           - get_products
           - get_product_by_id
           - create_product
           - update_product
           - delete_product
   ```

2. **Create Feature**:
   ```bash
   dart run clean_arch_cli:clean_arch_cli create --type feature --name products
   ```
   This creates:
   - Directory structure
   - Repository file with all methods
   - Empty usecase files
   - Empty data source files
   - Empty repository implementation files

3. **Generate Code**:
   ```bash
   dart run clean_arch_cli:clean_arch_cli generate
   ```
   With multi-file output enabled, this populates all the files with generated code.

4. **Implement Business Logic**:
   - Fill in TODO sections in data sources
   - Add custom business logic where needed
   - Write tests

## Implementation Details

### New Files Added

1. **Configuration Classes** (`generators/lib/core/config/generator_config.dart`):
   - `MultiFileOutputConfig`: Controls multi-file output behavior
   - `FeatureScaffoldingConfig`: Manages feature scaffolding settings
   - `FeatureDefinition`: Defines individual feature structure

2. **File Writer Service** (`generators/lib/core/services/feature_file_writer.dart`):
   - `FeatureFileWriter`: Handles file path resolution and writing
   - Methods for generating imports and complete files
   - Auto-creation logic for missing files

### Modified Generators

All generators now support multi-file output:

1. **RepoGenerator**: Writes repository interfaces to domain/repositories
2. **UsecaseGenerator**: Writes each usecase to its own file
3. **RemoteDataSrcGenerator**: Writes data sources to data/datasources
4. **RepoImplGenerator**: Writes implementations to data/repositories
5. **RepoImplTestGenerator**: Writes tests to test directory

Each generator:
- Checks if multi-file output is enabled
- Falls back to `.g.dart` if disabled or feature name can't be extracted
- Uses `FeatureFileWriter` for consistent file handling

### CLI Enhancements

**CreateCommand** (`cli/lib/commands/create_command.dart`):
- Checks for feature scaffolding configuration
- Parses YAML to extract feature methods
- Generates repository file with method signatures
- Creates empty files for usecases, data sources, and implementations

## Migration Guide

### Enabling Multi-File Output

1. **Backup your project** (recommended)

2. **Update config**:
   ```yaml
   multi_file_output:
     enabled: true
     auto_create_targets: true
   ```

3. **Create feature structure** (if not exists):
   ```bash
   dart run clean_arch_cli:clean_arch_cli create --type feature --name your_feature
   ```

4. **Run generator**:
   ```bash
   dart run clean_arch_cli:clean_arch_cli generate --delete-conflicting-outputs
   ```

5. **Verify generated files** in `lib/features/your_feature/`

### Disabling Multi-File Output

Set `enabled: false` in config and run generator again. Code will be written to `.g.dart` files as before.

## Troubleshooting

### "Could not write to file"

**Cause**: Target file or directory doesn't exist

**Solution**: 
- Ensure feature directory structure exists
- Enable `auto_create_targets: true`
- Check file permissions

### "Feature name can't be extracted"

**Cause**: Repository file not in standard `lib/features/{feature}/` structure

**Solution**:
- Move repository file to standard location
- Or disable multi-file output for that generator

### Generated files are empty

**Cause**: Generator fallback to `.g.dart` due to error

**Solution**:
- Check generator logs for warnings
- Verify feature structure matches expectations
- Ensure repository class name follows conventions (ends with `RepoTBG`)

## Best Practices

1. **Use both features together**: Enable both multi-file output and feature scaffolding for best experience

2. **Define features in config**: Even if not using scaffolding, having features defined helps with documentation

3. **Consistent naming**: Use snake_case for feature names and method names

4. **Version control**: Commit generated files so team members can see changes

5. **Review generated code**: Always review generated code before implementing business logic

## Examples

See the `example/lib/features/auth/` directory for a complete example of a feature using multi-file output.

## Support

For issues or questions:
- Check the main README.md
- Review the troubleshooting section
- Open an issue on GitHub

---

**Happy coding with Clean Architecture! 🚀**


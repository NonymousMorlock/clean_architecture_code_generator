# YAML Configuration for Fixture Generation

## How YAML Configuration Works with Fixture Generation

The model test generator now uses YAML configuration to determine the correct data types for fixture files, ensuring that the generated JSON fixtures match exactly what your API returns.

## Example Configuration

### YAML Config (`clean_arch_config.yaml`)

```yaml
model_test_config:
  # Global settings
  global:
    use_fixture_based_tests: true
    generate_null_safety_tests: true
    
  # Model-specific configurations
  user:
    field_types:
      created_at: "iso_string"     # API returns "2024-01-01T00:00:00.000Z"
      updated_at: "iso_string"     # API returns ISO strings
      birth_date: "timestamp_ms"   # API returns 1704067200000
      
  product:
    field_types:
      price: "double"              # API returns 29.99
      discount: "int"              # API returns 5
      created_at: "timestamp_s"    # API returns 1704067200
      
  order:
    field_types:
      total: "string"              # API returns "29.99" as string
      created_at: "timestamp_ms"   # API returns timestamp
      
  # Global defaults for unconfigured models
  defaults:
    datetime_format: "iso_string"  # Default DateTime format
    number_format: "double"        # Default number format
```

## Generated Fixtures Based on Configuration

### User Model (ISO String Dates)

**Generated Fixture** (`test/fixtures/user.json`):
```json
{
  "id": "Test id",
  "name": "Test name", 
  "email": "Test email",
  "created_at": "2024-01-01T00:00:00.000Z",  // ISO string per config
  "updated_at": "2024-01-01T00:00:00.000Z",  // ISO string per config
  "birth_date": 1704067200000,               // Timestamp ms per config
  "is_active": true
}
```

### Product Model (Mixed Types)

**Generated Fixture** (`test/fixtures/product.json`):
```json
{
  "id": "Test id",
  "name": "Test name",
  "price": 1.0,                    // Double per config
  "discount": 1,                   // Int per config  
  "created_at": 1704067200,        // Timestamp seconds per config
  "is_available": true
}
```

### Order Model (String Numbers)

**Generated Fixture** (`test/fixtures/order.json`):
```json
{
  "id": "Test id",
  "total": "1.0",                  // String per config
  "created_at": 1704067200000,     // Timestamp ms per config
  "status": "Test status"
}
```

## Generated Test Transformations

The generator also creates smart transformations to handle mismatches:

### User Model Test (created_at configured as "iso_string")

```dart
setUpAll(() {
  final fixtureString = fixture('user.json');
  tMap = jsonDecode(fixtureString) as DataMap;
  
  // Transform fixture data to match expected types (YAML config-aware)
  // Handle DateTime field: created_at (configured as: iso_string)
  if (tMap['created_at'] is int) {
    // Convert timestamp to ISO string for API consistency
    final timestamp = tMap['created_at'] as int;
    final dateTime = timestamp > 1000000000000
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    tMap['created_at'] = dateTime.toIso8601String();
  }
  
  // Handle DateTime field: birth_date (configured as: timestamp_ms)
  if (tMap['birth_date'] is String) {
    // Convert ISO string to timestamp for API consistency
    final dateTime = DateTime.parse(tMap['birth_date'] as String);
    tMap['birth_date'] = dateTime.millisecondsSinceEpoch;
  }

  // Create test model from fixture data
  tUserModel = UserModel.fromMap(tMap);
});
```

## Key Benefits

### ✅ **Consistent Test Data**
- Fixture data always matches what your API actually returns
- No more manual model vs fixture mismatches
- Test models created from fixture data ensure consistency

### ✅ **API Format Flexibility**
- Handle APIs that return dates as strings, timestamps, or mixed formats
- Support APIs that return numbers as strings or vice versa
- Configure per-model or use global defaults

### ✅ **Smart Transformations**
- Automatic conversion between different data types
- Handles edge cases like timestamp format detection
- YAML-driven transformation logic

### ✅ **Configuration Examples**

For different API patterns:

```yaml
# API returns all dates as ISO strings
user:
  field_types:
    created_at: "iso_string"
    updated_at: "iso_string"

# API returns dates as millisecond timestamps  
product:
  field_types:
    created_at: "timestamp_ms"
    
# API returns dates as second timestamps
order:
  field_types:
    created_at: "timestamp_s"
    
# API returns numbers as strings (common in financial APIs)
payment:
  field_types:
    amount: "string"        # "29.99" instead of 29.99
    tax: "string"           # "2.50" instead of 2.50
```

## Usage

1. **Configure your models** in `clean_arch_config.yaml`
2. **Annotate your models** with `@modelTestGen`
3. **Run code generation**: `dart run build_runner build`
4. **Create fixture files** using the generated templates
5. **Tests automatically work** with no manual model creation needed!

The fixture data and test models will always be in sync, eliminating the DateTime casting issues and fixture consistency problems.

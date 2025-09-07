import 'package:annotations/annotations.dart';

// Example usage of the new cubit generator
// This shows how to annotate a class to generate a cubit following
// the pattern from samples/adapter/project_cubit.dart

@cubitGen
class ProjectCubitTBG {
  // The generator will create a cubit with methods corresponding to use cases
  // Based on the repository methods, it will generate:
  // - Constructor with use case dependencies
  // - Methods that emit loading, success, and error states
  // - Proper state management following the established pattern
  
  // Note: This is just a demonstration - the actual cubit generation
  // happens based on the repository methods when @usecaseGen is used
}

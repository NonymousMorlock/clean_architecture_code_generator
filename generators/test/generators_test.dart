import 'package:generators/generators.dart';
import 'package:test/test.dart';

void main() {
  group('Generators Package', () {
    test('exports all core services', () {
      // Verify core exports are accessible
      expect(GeneratorConfig, isNotNull);
      expect(FeatureFileWriter, isNotNull);
    });

    test('exports all generator classes', () {
      // Verify generator exports are accessible
      expect(EntityGenerator, isNotNull);
      expect(ModelGenerator, isNotNull);
      expect(RepoGenerator, isNotNull);
      expect(UsecaseGenerator, isNotNull);
      expect(AdapterGenerator, isNotNull);
      expect(RemoteDataSrcGenerator, isNotNull);
      expect(LocalDataSrcGenerator, isNotNull);
      expect(RepoImplGenerator, isNotNull);
      expect(InjectionGenerator, isNotNull);
      expect(ModelTestGenerator, isNotNull);
      expect(UsecaseTestGenerator, isNotNull);
      expect(RepoImplTestGenerator, isNotNull);
    });

    test('exports model classes', () {
      // Verify model exports are accessible
      expect(Field, isNotNull);
      expect(Function, isNotNull);
    });

    test('exports visitor classes', () {
      // Verify visitor exports are accessible
      expect(ModelVisitor, isNotNull);
      expect(RepoVisitor, isNotNull);
    });
  });
}

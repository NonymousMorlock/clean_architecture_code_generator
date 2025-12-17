import 'package:code_builder/code_builder.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/src/models/param.dart';

/// Extensions for manipulating the [ClassBuilder] in code generation.
extension ClassBuilderExtensions on ClassBuilder {
  /// Adds the `props` getter required by Equatable.
  ///
  /// You can provide [params] to automatically generate `=> [field1, field2]`,
  /// or provide a custom [body] for complex logic.
  void addEquatableProps({
    Iterable<Param>? params,
    Code? body,
  }) {
    assert(
      params != null || body != null,
      'Must provide either fields or a body for props',
    );
    if (body != null) return _addPropsGetter(body: body);

    // Edge Case 1: Single Property optimization
    if (params!.length == 1) {
      final param = params.first;
      final isList = param.rawType.isDartCoreList;

      // OPTIMIZATION: If it is a NON-NULLABLE List, return it directly.
      // "get props => mySingleList;"
      if (isList && !param.isNullable) {
        _addPropsGetter(
          body: refer(param.name.camelCase).code,
        );
        return;
      }
    }

    // Default Case: Wrap everything in a list
    // "get props => [id, username, items];"
    _addPropsGetter(
      body: literalList([
        for (final param in params) refer(param.name.camelCase),
      ]).code,
    );
  }

  void _addPropsGetter({required Code body}) {
    methods.add(
      Method((m) {
        m
          ..name = 'props'
          ..type = MethodType.getter
          ..annotations.add(const Reference('override'))
          ..returns = const Reference('List<Object?>')
          ..lambda = true
          ..body = body;
      }),
    );
  }
}

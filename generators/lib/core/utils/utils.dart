import 'package:code_builder/code_builder.dart';
import 'package:generators/core/extensions/dart_type_extensions.dart';
import 'package:generators/generators.dart';

/// Utility class for code generation helpers.
sealed class Utils {
  /// Private constructor to prevent instantiation.
  const Utils();

  /// Adds a lint ignore comment for single-method abstract classes.
  ///
  /// When an interface has only one method, adds an ignore comment
  /// to suppress the `one_member_abstracts` lint warning.
  static void oneMemberAbstractHandler({
    required StringBuffer buffer,
    required int methodLength,
  }) {
    if (methodLength < 2) {
      buffer.writeAll(
        [
          '// I need this class to be an interface.',
          '// ignore_for_file: one_member_abstracts',
          '',
        ],
        '\n',
      );
    }
  }

  /// Discovers entity candidates used in a repository method.
  ///
  /// Scans the return type and parameters of the method to identify
  /// potential entity dependencies.
  //// Returns a set of entity names as strings.
  static Set<String> discoverMethodEntities(IFunction method) {
    final candidates = <String>{}
      // 1. Scan Return Type (e.g. Future<Either<Failure, List<User>>>)
      // This will automatically strip Future, discard Failure,
      // strip List, and find "User"
      ..addAll(method.rawType.entityCandidates);

    // 2. Scan Parameters (e.g. method(User params))
    if (method.params != null) {
      for (final param in method.params!) {
        candidates.addAll(param.rawType.entityCandidates);
      }
    }
    return candidates;
  }

  /// Determines if a lambda body should be used for a method.
  ///
  /// A lambda body is preferred for methods without parameters,
  /// or with a single named parameter, or with only a
  /// few positional parameters.
  /// Returns `true` if a lambda body is suitable, otherwise `false`.
  static bool shouldUseLambdaBody({
    required bool methodHasParams,
    required int namedArgumentsLength,
    required int positionalWhenArgumentsLength,
  }) {
    final hasSingleNamedParam =
        namedArgumentsLength == 1 && positionalWhenArgumentsLength == 0;

    final hasOnlyFewPositional =
        namedArgumentsLength == 0 && positionalWhenArgumentsLength <= 2;

    return !methodHasParams || hasSingleNamedParam || hasOnlyFewPositional;
  }

  /// Breaks a long string into adjacent string literals ('A' 'B')
  /// which satisfies the linter and allows DartFormatter to wrap lines.
  static Expression smartString(String text, {int threshold = 40}) {
    // 1. Short strings: Use standard code_builder literal
    if (text.length <= threshold) {
      return literalString(text);
    }

    // 2. Split logic
    final words = text.split(' ');
    final chunks = <String>[];
    var currentChunk = StringBuffer();

    for (final word in words) {
      if (currentChunk.length + word.length + 1 > threshold) {
        chunks.add(currentChunk.toString());
        currentChunk = StringBuffer();
      }
      // Add the space back here
      currentChunk.write('$word ');
    }

    if (currentChunk.isNotEmpty) {
      // Trim trailing space on last chunk
      chunks.add(currentChunk.toString().trimRight());
    }

    // 3. Construct Raw Code: 'Part 1 ' 'Part 2'
    final buffer = StringBuffer();

    for (var i = 0; i < chunks.length; i++) {
      var chunk = chunks[i];

      // CRITICAL: Since we are bypassing literalString,
      // we MUST manually escape!
      // 1. Escape backslashes first
      chunk = chunk.replaceAll(r'\', r'\\');
      // 2. Escape single quotes (since we wrap in single quotes)
      chunk = chunk.replaceAll("'", r"\'");
      // 3. Escape $ to prevent accidental interpolation if the string had it
      chunk = chunk.replaceAll(r'$', r'\$');

      // Add trailing space to the chunk content if it's not the last one
      if (i < chunks.length - 1) {
        chunk = '$chunk ';
      }

      buffer.write("'$chunk'");

      // Add a space between the string tokens so formatter handles them
      if (i < chunks.length - 1) {
        buffer.write(' ');
      }
    }

    // 4. Return as a CodeExpression
    // This tells code_builder: "Trust me, this string is valid
    // Dart expression code"
    return CodeExpression(Code(buffer.toString()));
  }
}

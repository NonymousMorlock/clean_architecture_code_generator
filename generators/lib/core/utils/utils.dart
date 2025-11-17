/// Utility class for code generation helpers.
abstract class Utils {
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
}

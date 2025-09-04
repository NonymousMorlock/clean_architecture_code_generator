abstract class Utils {
  const Utils();

  static oneMemberAbstractHandler({
    required StringBuffer buffer,
    required int methodLength,
  }) {
    if (methodLength < 2) {
      buffer.writeAll(
        [
          '// I need this class to be an interface.',
          '// ignore_for_file: one_member_abstracts',
          ''
        ],
        '\n',
      );
    }
  }
}

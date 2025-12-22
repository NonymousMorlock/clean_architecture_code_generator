import 'package:code_builder/code_builder.dart';

/// Extensions for manipulating [BlockBuilder] in code generation.
extension BlockBuilderExtensions on BlockBuilder {
  /// Generates verification expressions for a mock method call.
  ///
  /// [mockObjectName] is the name of the mock object.
  /// [methodName] is the name of the method being verified.
  /// [positionalVerifyArguments] are the positional arguments used
  /// in the verification.
  /// [namedVerifyArguments] are the named arguments used in the verification.
  void addVerificationExpressions({
    required String mockObjectName,
    required String methodName,
    required List<Expression> positionalVerifyArguments,
    required Map<String, Expression> namedVerifyArguments,
  }) {
    addExpression(
      refer('verify')
          .call([
            Method((methodBuilder) {
              final body = refer(mockObjectName)
                  .property(methodName)
                  .call(
                    positionalVerifyArguments,
                    namedVerifyArguments,
                  );
              methodBuilder
                ..lambda = true
                ..body = body.code;
            }).closure,
          ])
          .property('called')
          .call([literalNum(1)]),
    );
    addExpression(
      refer(
        'verifyNoMoreInteractions',
      ).call([refer(mockObjectName)]),
    );
  }
}

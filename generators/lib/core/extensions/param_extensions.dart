import 'package:code_builder/code_builder.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/src/models/param.dart';

/// Extension methods for DartType manipulation in code generation.
extension ParamExtensions on Param {
  /// Returns a fallback value based on the type.
  ///
  /// Used in `.empty` constructor generation to provide appropriate default
  /// values.
  ///
  /// DO NOT USE IN CASES WITH LOOSE TYPE CONSTRAINTS.
  Expression get fallbackValue {
    if (isNullable) return literalNull;

    final targetRawType = rawType;
    final targetType = type.rightType;
    final base = targetType.baseType.toLowerCase().replaceAll('?', '');

    if (targetRawType.isDartCoreSet) {
      return literalConstSet({});
    }
    if (targetRawType.isDartCoreList || targetRawType.isDartCoreIterable) {
      return literalConstList([]);
    }
    if (targetRawType.isDartCoreMap) {
      return literalConstMap({});
    }
    if (targetRawType.isDartCoreString) {
      return literalString('Test String');
    }
    if (targetRawType.isDartCoreDouble) {
      return literalNum(1.0);
    }
    if (targetRawType.isDartCoreNum || targetRawType.isDartCoreInt) {
      return literalNum(1);
    }
    if (targetRawType.isDartCoreBool) {
      return literalTrue;
    }
    if (base.contains('datetime')) {
      return const Reference('DateTime').newInstanceNamed('now', []);
    }
    if (targetRawType.isDartCoreRecord) {
      return literalConstRecord([], {});
    }
    if (base.isCustomType) {
      return Reference(targetType).newInstanceNamed('empty', []);
    }
    if (targetRawType.isDartCoreType) {
      return Reference(targetType).newInstance([]);
    }

    return literalNull;
  }
}

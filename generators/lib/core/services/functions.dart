import 'package:generators/src/models/function.dart';
import 'package:generators/src/models/param.dart';

/// Converts a parameter to its string representation with proper syntax.
///
/// Handles named parameters (wrapped in `{}`), optional positional parameters
/// (wrapped in `[]`), and regular positional parameters.
String paramToString(IFunction method, Param param) {
  if (param ==
          method.params!.firstWhere(
            (element) => element.isNamed,
            orElse: () => const Param.empty(),
          ) &&
      param !=
          method.params!.lastWhere(
            (element) => element.isNamed,
            orElse: () => const Param.empty(),
          )) {
    return '{${param.param}';
  } else if (param ==
          method.params!.lastWhere(
            (element) => element.isNamed,
            orElse: () => const Param.empty(),
          ) &&
      param !=
          method.params!.firstWhere(
            (element) => element.isNamed,
            orElse: () => const Param.empty(),
          )) {
    return '${param.param},}';
  } else if (param ==
          method.params!.firstWhere(
            (element) => element.isNamed,
            orElse: () => const Param.empty(),
          ) &&
      param ==
          method.params!.lastWhere(
            (element) => element.isNamed,
            orElse: () => const Param.empty(),
          )) {
    return '{${param.param}}';
  } else if (param ==
          method.params!.firstWhere(
            (element) => element.isOptionalPositional,
            orElse: () => const Param.empty(),
          ) &&
      param !=
          method.params!.lastWhere(
            (element) => element.isOptionalPositional,
            orElse: () => const Param.empty(),
          )) {
    return '[${param.param}';
  } else if (param ==
          method.params!.lastWhere(
            (element) => element.isOptionalPositional,
            orElse: () => const Param.empty(),
          ) &&
      param !=
          method.params!.firstWhere(
            (element) => element.isOptionalPositional,
            orElse: () => const Param.empty(),
          )) {
    return '${param.param},]';
  } else if (param ==
          method.params!.firstWhere(
            (element) => element.isOptionalPositional,
            orElse: () => const Param.empty(),
          ) &&
      param ==
          method.params!.lastWhere(
            (element) => element.isOptionalPositional,
            orElse: () => const Param.empty(),
          )) {
    return '[${param.param}]';
  } else {
    return param.param;
  }
}

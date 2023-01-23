import 'package:generators/src/models/function.dart';

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

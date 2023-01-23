import 'package:generators/src/models/function.dart';

String paramToString(IFunction method, Param param) {
  if(param == method.params!.firstWhere((element) => element.isNamed) &&
      param != method.params!.lastWhere((element) => element.isNamed)) {
    return '{${param.param}';
  } else if(param == method.params!.lastWhere((element) => element.isNamed)
      && param != method.params!.firstWhere((element) => element.isNamed)) {
    return '${param.param},}';
  } else if(param == method.params!.firstWhere((element) => element.isNamed)
      && param == method.params!.lastWhere((element) => element.isNamed)) {
    return '{${param.param}}';
  } else if(param == method.params!.firstWhere((element) => element
      .isOptionalPositional) && param != method.params!.lastWhere((element)
  => element.isOptionalPositional)) {
    return '[${param.param}';
  } else if(param == method.params!.lastWhere((element) => element
      .isOptionalPositional) && param != method.params!.firstWhere(
          (element) => element.isOptionalPositional)) {
    return '${param.param},]';
  } else if(param == method.params!.firstWhere((element) => element
      .isOptionalPositional) && param == method.params!.lastWhere(
          (element) => element.isOptionalPositional)) {
    return '[${param.param}]';
  } else {
    return param.param;
  }
}
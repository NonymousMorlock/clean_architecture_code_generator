import 'package:annotations/annotations.dart';
import 'package:flutter/widgets.dart';
import 'package:example/usecase.dart';

part 'main.g.dart';

@usecaseGen
class UsecaseTBG {
  String first_name;
  String last_name;

  Future<void> getStaff({required String name, required String eye}) async {}

  Future<String> removeStaff(String name) async {}

  Future<String> goRoute() async {}
}

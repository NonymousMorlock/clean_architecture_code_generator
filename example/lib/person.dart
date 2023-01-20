// ignore_for_file: unused_import

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'typedefs.dart';
import 'dart:convert';

part 'person.g.dart';

@modelGen
@entityGen
class PersonTBG {
  String first_name;
  String last_name;
  @required
  bool is_adult = false;
  List<int> numbers;
  double rate;
  List<String> user_names;
  DateTime date;
  int age;
}

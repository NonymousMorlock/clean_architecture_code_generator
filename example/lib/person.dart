// ignore_for_file: unused_import

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'typedefs.dart';
import 'dart:convert';

part 'person.g.dart';

// @modelGen
// @entityGen
// @modelTestGen
class TankTBG {
  @required
  String tank_capacity;
  @required
  String tank_name;
  @required
  String beginning_stock_balance;
  @required
  int stock_type;
  @required
  int branch_id;
  @required
  int number_of_meters;
}

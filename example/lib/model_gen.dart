// ignore_for_file: unused_import

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'typedefs.dart';
import 'dart:convert';

part 'model_gen.g.dart';

@entityGen
@modelGen
@modelTestGen
class MeterReportTBG {
  @required
  int id;
  @required
  double meter_reading;
  @required
  double litre_rate;
  @required
  DateTime date_created;
  @required
  DateTime updated_date;
  @required
  int branch_id;
  @required
  int stock_type;
  @required
  int meter_id;
  @required
  int staff_id;
}

final request = {
  "meter_reading": "20.00",
  "litre_rate": "11.23",
  "branch_id": 4,
  "stock_type": 1,
  "meter_id": 1,
  "staff_id": 3
};

final response = {
  "id": 12,
  "meter_reading": "20.00",
  "litre_rate": "11.23",
  "date_created": "2023-03-08T08:02:08.599577Z",
  "updated_date": "2023-03-08T08:02:08.599610Z",
  "branch_id": 4,
  "stock_type": 1,
  "meter_id": 1,
  "staff_id": 3
};

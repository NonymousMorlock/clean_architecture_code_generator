// ignore_for_file: unused_import

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'typedefs.dart';
import 'dart:convert';

part 'model_gen.g.dart';

@modelGen
@modelTestGen
class ClientTBG {
  @required
  final String id;
  @required
  final String name;
  @required
  final String totalSpent;
}

@modelGen
@modelTestGen
class URLTBG {
  @required
  final String url;
  @required
  final String title;
}

@modelGen
@modelTestGen
class MilestoneTBG {
  @required
  final String id;
  @required
  final String projectId;
  final String shortDescription;
  final List<String> notes;
  @required
  final double amountPaid;
  @required
  final DateTime date;
}

@modelGen
@modelTestGen
class ProjectTBG {
  @required
  final String id;
  @required
  final String projectName;
  @required
  final String clientName;
  final List<URL> urls;
  @required
  final double budget;
  @required
  final double totalPaid;
  @required
  final int numberOfMilestonesSoFar;
  final String clientId;
  @required
  final DateTime startDate;
  final DateTime endDate;
}

class URL {}

class Milestone {}

final request = {
  "id": 3,
  "drivers_name": null,
  "plate_number": null,
  "expanse_name": null,
  "expense_type": "Miscellanous",
  "amount": "10.00",
  "date_created": "2023-03-25T13:04:47.649399Z",
  "updated_date": "2023-03-25T13:04:47.649424Z",
  "branch_id": 1,
  "staff_id": 1
};

final response = [
  {
    "id": 2,
    "drivers_name": null,
    "plate_number": null,
    "expanse_name": null,
    "expense_type": "Miscellanous",
    "amount": "10.00",
    "date_created": "2023-03-25T13:04:26.771282Z",
    "updated_date": "2023-03-25T13:04:26.771300Z",
    "branch_id": 1,
    "staff_id": 1
  },
  {
    "id": 3,
    "drivers_name": null,
    "plate_number": null,
    "expanse_name": null,
    "expense_type": "Miscellanous",
    "amount": "10.00",
    "date_created": "2023-03-25T13:04:47.649399Z",
    "updated_date": "2023-03-25T13:04:47.649424Z",
    "branch_id": 1,
    "staff_id": 1
  }
];

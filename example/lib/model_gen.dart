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
  final String image;
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
  @required
  final String title;
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
  @required
  final String shortDescription;
  final String longDescription;
  final List<String> notes;
  final List<URL> urls;
  @required
  final double budget;
  final bool isFixed;
  final bool isOneTime;
  @required
  final String projectType;
  final List<String> tools;
  @required
  final double totalPaid;
  @required
  final int numberOfMilestonesSoFar;
  final String image;
  final List<String> images;
  final String clientId;
  @required
  final DateTime startDate;
  final DateTime deadline;
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

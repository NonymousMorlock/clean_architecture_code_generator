// ignore_for_file: unused_import

import 'dart:convert';

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'typedefs.dart';

part 'model_gen.g.dart';

// @modelTestGen
// @modelGen
// @entityGen
class FacultyTBG {
  @required
  final String id;
  @required
  final String name;
}
//
// @modelTestGen
// @modelGen
// @entityGen
// class CourseTBG {
//   @required
//   final String id;
//   @required
//   final String name;
//   @required
//   final Faculty faculty;
// }
//
// @modelTestGen
// @modelGen
// @entityGen
// class LevelTBG {
//   @required
//   final String id;
//   @required
//   final String name;
//   @required
//   final Course course;
// }

class Course {}

class Faculty {}

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

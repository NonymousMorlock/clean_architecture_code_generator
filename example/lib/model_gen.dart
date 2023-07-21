// ignore_for_file: unused_import

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'typedefs.dart';
import 'dart:convert';

part 'model_gen.g.dart';

// @entityGen
@modelGen
@modelTestGen
class ExamTBG {
  @required
  final String id;
  @required
  final String courseId;
}

@modelGen
@modelTestGen
class ExamQuestionTBG {
  @required
  final String id;
  @required
  final String examId;
  @required
  final String courseId;
  @required
  final String questionText;
  @required
  final List<QuestionChoice> choices;
}

@modelGen
@modelTestGen
class QuestionChoiceTBG {
  @required
  final String questionId;
  @required
  final String identifier;
  @required
  final String choiceAnswer;
}

// @modelGen
// @modelTestGen
class UserChoiceTBG {
  @required
  final String questionId;
  @required
  final String correctChoice;
  @required
  final String userChoice;
  @required
  final String choiceId;
}

@modelGen
@modelTestGen
class UserExamTBG {
  @required
  final String examId;
  @required
  final String courseId;
  @required
  final List<UserChoice> answers;
}

class UserChoice {
}

class QuestionChoice {
}

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

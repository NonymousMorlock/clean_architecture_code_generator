// ignore_for_file: unused_import

import 'package:annotations/annotations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'typedefs.dart';
import 'dart:convert';

part 'model_gen.g.dart';

// @modelGen
// @modelTestGen
// @entityGen
class ProductTBG {
  @required
  final String id;
  @required
  final String name;
  @required
  final String description;
  @required
  final double price;
  @required
  final double rating;
  @required
  final List<Color> colours;
  @required
  final String image;
  @required
  final List<String> images;
  @required
  final List<String> reviewIds;
  @required
  final int numberOfReviews;
  @required
  final List<String> sizes;
  @required
  final ProductCategory category;
  final String genderAgeCategory;
  @required
  final int countInStock;
}

// @modelTestGen
// @modelGen
// @entityGen
class ProductCategoryTBG {
  @required
  final String id;
  final String name;
  final String colour;
}

// @modelTestGen
// @modelGen
// @entityGen
class ReviewTBG {
  @required
  final String id;
  @required
  final String userId;
  @required
  final String userName;
  @required
  final String comment;
  @required
  final double rating;
  @required
  final DateTime date;
}

class ProductCategory {}

class Address {}

class WishlistProduct {}

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

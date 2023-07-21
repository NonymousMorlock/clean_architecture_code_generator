// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_gen.dart';

// **************************************************************************
// EntityGenerator
// **************************************************************************

class ExpenseReport extends Equatable {
  const ExpenseReport({
    required this.id,
    this.driversName,
    this.plateNumber,
    this.expanseName,
    required this.expenseType,
    required this.amount,
    required this.dateCreated,
    required this.updatedDate,
    required this.branchId,
    required this.staffId,
  });

  ExpenseReport.empty()
      : id = 1,
        driversName = "Test String",
        plateNumber = "Test String",
        expanseName = "Test String",
        expenseType = "Test String",
        amount = 1,
        dateCreated = DateTime.now(),
        updatedDate = DateTime.now(),
        branchId = 1,
        staffId = 1;

  final int id;
  final String? driversName;
  final String? plateNumber;
  final String? expanseName;
  final String expenseType;
  final double amount;
  final DateTime dateCreated;
  final DateTime updatedDate;
  final int branchId;
  final int staffId;

  @override
  List<dynamic> get props => [
        id,
        driversName,
        plateNumber,
        expanseName,
        expenseType,
        amount,
        dateCreated,
        updatedDate,
        branchId,
        staffId,
      ];
}

// **************************************************************************
// ModelGenerator
// **************************************************************************

// import typedefs
// import entity

class ExpenseReportModel extends ExpenseReport {
  const ExpenseReportModel({
    required super.id,
    super.driversName,
    super.plateNumber,
    super.expanseName,
    required super.expenseType,
    required super.amount,
    required super.dateCreated,
    required super.updatedDate,
    required super.branchId,
    required super.staffId,
  });

  ExpenseReportModel.empty()
      : this(
          id: 1,
          driversName: "Test String",
          plateNumber: "Test String",
          expanseName: "Test String",
          expenseType: "Test String",
          amount: 1,
          dateCreated: DateTime.now(),
          updatedDate: DateTime.now(),
          branchId: 1,
          staffId: 1,
        );

  factory ExpenseReportModel.fromJson(String source) =>
      ExpenseReportModel.fromMap(jsonDecode(source) as DataMap);

  ExpenseReportModel.fromMap(DataMap map)
      : this(
          id: (map['id'] as num).toInt(),
          driversName: map['drivers_name'] as String?,
          plateNumber: map['plate_number'] as String?,
          expanseName: map['expanse_name'] as String?,
          expenseType: map['expense_type'] as String,
          amount: (map['amount'] as num).toDouble(),
          dateCreated: DateTime.parse(map['date_created'] as String),
          updatedDate: DateTime.parse(map['updated_date'] as String),
          branchId: (map['branch_id'] as num).toInt(),
          staffId: (map['staff_id'] as num).toInt(),
        );

  ExpenseReportModel copyWith({
    int? id,
    String? driversName,
    String? plateNumber,
    String? expanseName,
    String? expenseType,
    double? amount,
    DateTime? dateCreated,
    DateTime? updatedDate,
    int? branchId,
    int? staffId,
  }) {
    return ExpenseReportModel(
      id: id ?? this.id,
      driversName: driversName ?? this.driversName,
      plateNumber: plateNumber ?? this.plateNumber,
      expanseName: expanseName ?? this.expanseName,
      expenseType: expenseType ?? this.expenseType,
      amount: amount ?? this.amount,
      dateCreated: dateCreated ?? this.dateCreated,
      updatedDate: updatedDate ?? this.updatedDate,
      branchId: branchId ?? this.branchId,
      staffId: staffId ?? this.staffId,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'drivers_name': driversName,
      'plate_number': plateNumber,
      'expanse_name': expanseName,
      'expense_type': expenseType,
      'amount': amount,
      'date_created': dateCreated.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
      'branch_id': branchId,
      'staff_id': staffId,
    };
  }

  String toJson() => jsonEncode(toMap());
}

// **************************************************************************
// ModelTestGenerator
// **************************************************************************

import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  final tExpenseReportModel = ExpenseReportModel.empty();

  group('ExpenseReportModel', () {
    test('should be a subclass of [ExpenseReport] entity', () async {
      expect(tExpenseReportModel, isA<ExpenseReport>());
    });

    group('fromMap', () {
      test(
          'should return a valid [ExpenseReportModel] when the JSON is not null',
          () async {
        final map = jsonDecode(fixture('expense_report.json')) as DataMap;
        final result = ExpenseReportModel.fromMap(map);
        expect(result, tExpenseReportModel);
      });
    });

    group('fromJson', () {
      test(
          'should return a valid [ExpenseReportModel] when the JSON is not null',
          () async {
        final json = fixture('expense_report.json');
        final result = ExpenseReportModel.fromJson(json);
        expect(result, tExpenseReportModel);
      });
    });

    group('toMap', () {
      test('should return a Dart map containing the proper data', () async {
        final map = jsonDecode(fixture('expense_report.json')) as DataMap;
        final result = tExpenseReportModel.toMap();
        expect(result, map);
      });
    });

    group('toJson', () {
      test('should return a JSON string containing the proper data', () async {
        final json = jsonEncode(jsonDecode(fixture('expense_report.json')));
        final result = tExpenseReportModel.toJson();
        expect(result, json);
      });
    });

    group('copyWith', () {
      test('should return a new [ExpenseReportModel] with the same values',
          () async {
        final result = tExpenseReportModel.copyWith(id: 0);
        expect(result.id, equals(0));
      });
    });
  });
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_gen.dart';

// **************************************************************************
// EntityGenerator
// **************************************************************************

class MeterReport extends Equatable {
  const MeterReport({
    required this.id,
    required this.meterReading,
    required this.litreRate,
    required this.dateCreated,
    required this.updatedDate,
    required this.branchId,
    required this.stockType,
    required this.meterId,
    required this.staffId,
  });

  MeterReport.empty()
      : id = 1,
        meterReading = 1,
        litreRate = 1,
        dateCreated = DateTime.now(),
        updatedDate = DateTime.now(),
        branchId = 1,
        stockType = 1,
        meterId = 1,
        staffId = 1;

  final int id;
  final double meterReading;
  final double litreRate;
  final DateTime dateCreated;
  final DateTime updatedDate;
  final int branchId;
  final int stockType;
  final int meterId;
  final int staffId;

  @override
  List<dynamic> get props => [
        id,
        meterReading,
        litreRate,
        dateCreated,
        updatedDate,
        branchId,
        stockType,
        meterId,
        staffId,
      ];
}

// **************************************************************************
// ModelGenerator
// **************************************************************************

// import typedefs
// import entity

class MeterReportModel extends MeterReport {
  const MeterReportModel({
    required super.id,
    required super.meterReading,
    required super.litreRate,
    required super.dateCreated,
    required super.updatedDate,
    required super.branchId,
    required super.stockType,
    required super.meterId,
    required super.staffId,
  });

  MeterReportModel.empty()
      : this(
          id: 1,
          meterReading: 1,
          litreRate: 1,
          dateCreated: DateTime.now(),
          updatedDate: DateTime.now(),
          branchId: 1,
          stockType: 1,
          meterId: 1,
          staffId: 1,
        );

  factory MeterReportModel.fromJson(String source) =>
      MeterReportModel.fromMap(jsonDecode(source) as DataMap);

  MeterReportModel.fromMap(DataMap map)
      : this(
          id: (map['id'] as num).toInt(),
          meterReading: (map['meter_reading'] as num).toDouble(),
          litreRate: (map['litre_rate'] as num).toDouble(),
          dateCreated: DateTime.parse(map['date_created'] as String),
          updatedDate: DateTime.parse(map['updated_date'] as String),
          branchId: (map['branch_id'] as num).toInt(),
          stockType: (map['stock_type'] as num).toInt(),
          meterId: (map['meter_id'] as num).toInt(),
          staffId: (map['staff_id'] as num).toInt(),
        );

  MeterReportModel copyWith({
    int? id,
    double? meterReading,
    double? litreRate,
    DateTime? dateCreated,
    DateTime? updatedDate,
    int? branchId,
    int? stockType,
    int? meterId,
    int? staffId,
  }) {
    return MeterReportModel(
      id: id ?? this.id,
      meterReading: meterReading ?? this.meterReading,
      litreRate: litreRate ?? this.litreRate,
      dateCreated: dateCreated ?? this.dateCreated,
      updatedDate: updatedDate ?? this.updatedDate,
      branchId: branchId ?? this.branchId,
      stockType: stockType ?? this.stockType,
      meterId: meterId ?? this.meterId,
      staffId: staffId ?? this.staffId,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'meter_reading': meterReading,
      'litre_rate': litreRate,
      'date_created': dateCreated.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
      'branch_id': branchId,
      'stock_type': stockType,
      'meter_id': meterId,
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
  final tMeterReportModel = MeterReportModel.empty();

  group('MeterReportModel', () {
    test('should be a subclass of [MeterReport] entity', () async {
      expect(tMeterReportModel, isA<MeterReport>());
    });

    group('fromMap', () {
      test('should return a valid [MeterReportModel] when the JSON is not null',
          () async {
        final map = jsonDecode(fixture('meterreport.json')) as DataMap;
        final result = MeterReportModel.fromMap(map);
        expect(result, tMeterReportModel);
      });
    });

    group('fromJson', () {
      test('should return a valid [MeterReportModel] when the JSON is not null',
          () async {
        final json = fixture('meterreport.json');
        final result = MeterReportModel.fromJson(json);
        expect(result, tMeterReportModel);
      });
    });

    group('toMap', () {
      test('should return a Dart map containing the proper data', () async {
        final map = jsonDecode(fixture('meterreport.json')) as DataMap;
        final result = tMeterReportModel.toMap();
        expect(result, map);
      });
    });

    group('toJson', () {
      test('should return a JSON string containing the proper data', () async {
        final json = jsonEncode(jsonDecode(fixture('meterreport.json')));
        final result = tMeterReportModel.toJson();
        expect(result, json);
      });
    });

    group('copyWith', () {
      test('should return a new [MeterReportModel] with the same values',
          () async {
        final result = tMeterReportModel.copyWith(id: 0);
        expect(result.id, equals(0));
      });
    });
  });
}

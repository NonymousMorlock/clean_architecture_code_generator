// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// ModelTestGenerator
// **************************************************************************

import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:example/person.dart';

void main() {
  final tTankModel = TankModel(
    tankCapacity: "Test String",
    tankName: "Test String",
    beginningStockBalance: "Test String",
    stockType: 1,
    branchId: 1,
    numberOfMeters: 1,
  );

  group('TankModel', () {
    test('should be a subclass of [Tank] entity', () async {
      expect(TankModel, isA<Tank>());
    });

    group('fromMap', () {
      test('should return a valid [TankModel] when the JSON is not null',
          () async {
        final map = jsonDecode(fixture('tank.json')) as DataMap;
        final result = TankModel.fromMap(map);
        expect(result, TankModel);
      });
    });

    group('fromJson', () {
      test('should return a valid [TankModel] when the JSON is not null',
          () async {
        final json = fixture('tank.json');
        final result = TankModel.fromJson(json);
        expect(result, TankModel);
      });
    });

    group('toMap', () {
      test('should return a Dart map containing the proper data', () async {
        final map = jsonDecode(fixture('tank.json')) as DataMap;
        final result = TankModel.toMap();
        expect(result, map);
      });
    });

    group('toJson', () {
      test('should return a JSON string containing the proper data', () async {
        final json = jsonEncode(jsonDecode(fixture('tank.json')));
        final result = TankModel.toJson();
        expect(result, json);
      });
    });

    group('copyWith', () {
      test('should return a new [TankModel] with the same values', () async {
        final result = tTankModel.copyWith(tankCapacity: '');
        expect(result.tankCapacity, equals(''));
      });
    });
  });
}

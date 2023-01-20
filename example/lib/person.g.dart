// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// EntityGenerator
// **************************************************************************

class Person extends Equatable {
  const Person({
    this.firstName,
    this.lastName,
    required this.isAdult,
    this.numbers,
    this.rate,
    this.userNames,
    this.date,
    this.age,
  });

  final String? firstName;
  final String? lastName;
  final bool isAdult;
  final List<int>? numbers;
  final double? rate;
  final List<String>? userNames;
  final DateTime? date;
  final int? age;

  @override
  List<dynamic> get props => [
        firstName,
        lastName,
        isAdult,
        numbers,
        rate,
        userNames,
        date,
        age,
      ];
}

// **************************************************************************
// ModelGenerator
// **************************************************************************

// import typedefs
// import entity

class PersonModel extends Person {
  const PersonModel({
    super.firstName,
    super.lastName,
    required super.isAdult,
    super.numbers,
    super.rate,
    super.userNames,
    super.date,
    super.age,
  });

  factory PersonModel.fromJson(String source) =>
      PersonModel.fromMap(jsonDecode(source) as DataMap);

  PersonModel.fromMap(DataMap map)
      : this(
          firstName: map['first_name'] as String?,
          lastName: map['last_name'] as String?,
          isAdult: map['is_adult'] as bool,
          numbers: map['numbers'] != null
              ? List<int>.from(map['numbers'] as List<dynamic>)
              : null,
          rate: (map['rate'] as num?)?.toDouble(),
          userNames: map['user_names'] != null
              ? List<String>.from(map['user_names'] as List<dynamic>)
              : null,
          date: map['date'] == null
              ? null
              : DateTime.parse(map['date'] as String),
          age: (map['age'] as num?)?.toInt(),
        );

  PersonModel copyWith({
    String? firstName,
    String? lastName,
    bool? isAdult,
    List<int>? numbers,
    double? rate,
    List<String>? userNames,
    DateTime? date,
    int? age,
  }) {
    return PersonModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isAdult: isAdult ?? this.isAdult,
      numbers: numbers ?? this.numbers,
      rate: rate ?? this.rate,
      userNames: userNames ?? this.userNames,
      date: date ?? this.date,
      age: age ?? this.age,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'is_adult': isAdult,
      'numbers': numbers,
      'rate': rate,
      'user_names': userNames,
      'date': date?.toIso8601String(),
      'age': age,
    };
  }

  String toJson() => jsonEncode(toMap());
}

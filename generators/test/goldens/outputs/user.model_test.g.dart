/*
{
  "id": "Test String",
  "Email": "Test String",
  "Name": "Test String",
  "favoriteItemIds": [],
  "addresses": null,
  "created_at": null
}
*/
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();
void main() {
  late final UserModel tUserModel;
  late final DataMap tMap;
  setUpAll(() {
    final fixtureString = fixture('user.json');
    tMap = (jsonDecode(fixtureString) as DataMap);
    tMap['PrimaryAddress'] = AddressModel.empty().toMap();
    tUserModel = UserModel.empty().copyWith();
  });
  test(
    'should be a subclass of User entity',
    () {
      expect(
        tUserModel,
        isA<User>(),
      );
    },
  );
  group(
    'fromMap',
    () {
      test(
        'should return a valid model when the map is valid',
        () {
          final result = UserModel.fromMap(tMap);
          expect(
            result,
            isA<UserModel>(),
          );
          expect(
            result,
            equals(tUserModel),
          );
        },
      );
    },
  );
  group(
    'toMap',
    () {
      test(
        'should return a JSON map containing the proper data',
        () {
          final result = tUserModel.toMap();
          expect(
            result,
            isA<DataMap>(),
          );
          expect(
            result,
            equals(tMap),
          );
        },
      );
    },
  );
  group(
    'copyWith',
    () {
      test(
        'should return a copy of the model with updated fields',
        () {
          final result = tUserModel.copyWith(id: 'Updated id');
          expect(
            result,
            isA<UserModel>(),
          );
          expect(
            result.id,
            equals('Updated id'),
          );
          expect(
            result.email,
            equals(tUserModel.email),
          );
        },
      );
      test(
        'should return the same instance when no parameters are provided',
        () {
          final result = tUserModel.copyWith();
          expect(
            result,
            equals(tUserModel),
          );
        },
      );
    },
  );
  group(
    'fromJson',
    () {
      test(
        'should return a valid model when the JSON string is valid',
        () {
          final jsonString = jsonEncode(tMap);
          final result = UserModel.fromJson(jsonString);
          expect(
            result,
            isA<UserModel>(),
          );
          expect(
            result,
            equals(tUserModel),
          );
        },
      );
    },
  );
  group(
    'toJson',
    () {
      test(
        'should return a JSON string containing the proper data',
        () {
          final result = tUserModel.toJson();
          expect(
            result,
            isA<String>(),
          );
          final resultMap = (jsonDecode(result) as DataMap);
          expect(
            resultMap,
            equals(tMap),
          );
        },
      );
    },
  );
}

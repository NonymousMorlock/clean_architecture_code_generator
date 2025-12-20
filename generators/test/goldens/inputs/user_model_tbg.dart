// I need the unused constructor parameters for code generation
// ignore_for_file: avoid_unused_constructor_parameters

import 'package:annotations/annotations.dart';

part 'user_model_tbg.g.dart';

@modelTestGen
@modelGen
@entityGen
class UserTBG {
  const UserTBG({
    required String id,
    required String Email,
    required String Name,
    required Address PrimaryAddress,
    required List<int> favoriteItemIds,
    List<Address>? addresses,
    DateTime? created_at,
  });
}

class Address {}

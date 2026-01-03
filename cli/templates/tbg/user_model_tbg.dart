import 'package:annotations/annotations.dart';

part 'user_model_tbg.g.dart';

@modelTestGen
@modelGen
@entityGen
class UserTBG {
  const UserTBG({
    required this.id,
    required this.Email,
    required this.Name,
    required this.PrimaryAddress,
    required this.favoriteItemIds,
    this.addresses,
    this.created_at,
    this.updatedAt,
  });

  final String id;
  final String Email;
  final String Name;
  final Address PrimaryAddress;
  final List<int> favoriteItemIds;
  final List<Address>? addresses;
  final DateTime? created_at;
  final DateTime? updatedAt;
}

class Address {}

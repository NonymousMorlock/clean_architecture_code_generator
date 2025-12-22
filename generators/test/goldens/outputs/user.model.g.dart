class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.primaryAddress,
    required super.favoriteItemIds,
    super.addresses,
    super.createdAt,
  });
  UserModel.empty()
    : this(
        id: 'Test String',
        email: 'Test String',
        name: 'Test String',
        primaryAddress: AddressModel.empty(),
        favoriteItemIds: const [],
        addresses: null,
        createdAt: null,
      );
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap((jsonDecode(source) as DataMap));
  UserModel.fromMap(DataMap map)
    : this(
        id: (map['id'] as String),
        email: (map['Email'] as String),
        name: (map['Name'] as String),
        primaryAddress: AddressModel.fromMap(
          (map['PrimaryAddress'] as DataMap),
        ),
        favoriteItemIds: List<int>.from(
          (map['favoriteItemIds'] as List<dynamic>),
        ),
        addresses: map['addresses'] != null
            ? List<DataMap>.from(
                (map['addresses'] as List<dynamic>),
              ).map(AddressModel.fromMap).toList()
            : null,
        createdAt: map['created_at'] != null
            ? _parseDateTime(map['created_at'])
            : null,
      );
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    AddressModel? primaryAddress,
    List<int>? favoriteItemIds,
    List<AddressModel>? addresses,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'Email': email,
      'Name': name,
      'PrimaryAddress': primaryAddress.toMap(),
      'favoriteItemIds': favoriteItemIds,
      'addresses': addresses?.map((e) => e.toMap()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());
  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    } else if (value is int) {
      return value > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    } else if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    } else {
      throw FormatException('Invalid DateTime format: $value');
    }
  }
}

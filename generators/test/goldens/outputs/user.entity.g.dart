class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.primaryAddress,
    required this.favoriteItemIds,
    this.addresses,
    this.createdAt,
  });
  User.empty()
    : this(
        id: 'Test String',
        email: 'Test String',
        name: 'Test String',
        primaryAddress: Address.empty(),
        favoriteItemIds: const [],
        addresses: null,
        createdAt: null,
      );
  final String id;
  final String email;
  final String name;
  final Address primaryAddress;
  final List<int> favoriteItemIds;
  final List<Address>? addresses;
  final DateTime? createdAt;
  @override
  List<Object?> get props => [
    id,
    email,
    name,
    primaryAddress,
    favoriteItemIds,
    addresses,
    createdAt,
  ];
}

class OwnerMenuItem {
  const OwnerMenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.available = true,
  });

  final String id;
  final String name;
  final int price;
  final String category;
  final bool available;

  OwnerMenuItem copyWith({
    String? id,
    String? name,
    int? price,
    String? category,
    bool? available,
  }) {
    return OwnerMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      available: available ?? this.available,
    );
  }
}
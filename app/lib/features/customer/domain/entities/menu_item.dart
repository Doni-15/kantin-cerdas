/// Data menu yang digunakan oleh aplikasi.
class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.stallId,
    required this.stallName,
    required this.block,
    required this.price,
    required this.waitTime,
    required this.description,
    required this.category,
    required this.available,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String stallId;
  final String stallName;
  final String block;

  /// Harga dalam rupiah utuh. Pemformatan tampilan dilakukan di presentation.
  final int price;

  /// Estimasi waktu yang diberikan oleh sumber data.
  final String waitTime;

  final String description;
  final String category;

  /// Status ketersediaan yang diberikan oleh sumber data.
  final bool available;

  /// URL foto menu yang telah tervalidasi keamanannya (opsional).
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItem &&
          other.id == id &&
          other.name == name &&
          other.stallId == stallId &&
          other.stallName == stallName &&
          other.block == block &&
          other.price == price &&
          other.waitTime == waitTime &&
          other.description == description &&
          other.category == category &&
          other.available == available &&
          other.imageUrl == imageUrl);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    stallId,
    stallName,
    block,
    price,
    waitTime,
    description,
    category,
    available,
    imageUrl,
  );
}

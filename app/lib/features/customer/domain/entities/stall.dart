import 'package:kantin_cerdas/core/utils/collection_equality.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';

/// Data stan beserta menu yang diberikan oleh sumber data.
class Stall {
  Stall({
    required this.id,
    required this.name,
    required this.block,
    required this.waitTime,
    required this.description,
    required List<MenuItem> menus,
    required this.isOpen,
    this.imageUrl,
  }) : menus = List<MenuItem>.unmodifiable(menus);

  final String id;
  final String name;
  final String block;

  /// Estimasi waktu yang diberikan oleh sumber data.
  final String waitTime;

  final String description;

  /// Salinan daftar menu yang tidak dapat diubah.
  final List<MenuItem> menus;

  /// Status buka yang diberikan oleh sumber data.
  final bool isOpen;

  /// URL foto stan yang telah tervalidasi keamanannya (opsional).
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stall &&
          other.id == id &&
          other.name == name &&
          other.block == block &&
          other.waitTime == waitTime &&
          other.description == description &&
          other.isOpen == isOpen &&
          other.imageUrl == imageUrl &&
          listEquals(other.menus, menus));

  @override
  int get hashCode => Object.hash(
    id,
    name,
    block,
    waitTime,
    description,
    isOpen,
    imageUrl,
    Object.hashAll(menus),
  );
}

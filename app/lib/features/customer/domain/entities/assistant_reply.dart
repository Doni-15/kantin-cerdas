import 'package:kantin_cerdas/core/utils/collection_equality.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';

class AssistantReply {
  AssistantReply({required this.message, required List<MenuItem> menus})
    : menus = List.unmodifiable(menus) {
    if (message.trim().isEmpty) throw ArgumentError('Balasan kosong.');
  }
  final String message;

  /// Menu nyata yang sudah diverifikasi oleh layanan terhadap katalog.
  final List<MenuItem> menus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssistantReply &&
          other.message == message &&
          listEquals(other.menus, menus));

  @override
  int get hashCode => Object.hash(message, Object.hashAll(menus));
}

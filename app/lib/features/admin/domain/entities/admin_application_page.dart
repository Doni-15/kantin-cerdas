import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/core/utils/collection_equality.dart';

class AdminApplicationPage {
  AdminApplicationPage({
    required List<CanteenApplication> items,
    this.nextCursor,
  }) : items = List.unmodifiable(items) {
    if ((nextCursor != null && nextCursor!.trim().isEmpty) ||
        items.map((item) => item.id).toSet().length != items.length) {
      throw ArgumentError('Halaman pengajuan tidak valid.');
    }
  }
  final List<CanteenApplication> items;
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminApplicationPage &&
          other.nextCursor == nextCursor &&
          listEquals(other.items, items));

  @override
  int get hashCode => Object.hash(nextCursor, Object.hashAll(items));
}

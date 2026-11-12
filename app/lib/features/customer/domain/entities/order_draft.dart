import 'package:kantin_cerdas/core/utils/collection_equality.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_state.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';

/// Pilihan satu menu yang hendak dipesan.
class OrderDraftItem {
  OrderDraftItem({
    required this.menuId,
    required this.quantity,
    this.note = '',
  }) {
    if (menuId.trim().isEmpty) {
      throw ArgumentError.value(
        menuId,
        'menuId',
        'ID menu tidak boleh kosong.',
      );
    }

    if (!CustomerInputLimits.validQuantity(quantity)) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Jumlah item harus 1–99.',
      );
    }
    if (!CustomerInputLimits.validNote(note)) {
      throw ArgumentError('Catatan menu maksimal 300 karakter.');
    }
  }

  final String menuId;
  final int quantity;
  final String note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderDraftItem &&
          other.menuId == menuId &&
          other.quantity == quantity &&
          other.note == note);

  @override
  int get hashCode => Object.hash(menuId, quantity, note);
}

/// Snapshot pilihan pengguna sebelum pesanan dibuat.
class OrderDraft {
  OrderDraft({
    required this.stallId,
    required List<OrderDraftItem> items,
    this.orderNote = '',
  }) : items = List<OrderDraftItem>.unmodifiable(items) {
    if (!CustomerInputLimits.validNote(orderNote)) {
      throw ArgumentError('Catatan pesanan maksimal 300 karakter.');
    }
    if (stallId.trim().isEmpty) {
      throw ArgumentError.value(
        stallId,
        'stallId',
        'ID stan tidak boleh kosong.',
      );
    }

    if (this.items.isEmpty) {
      throw ArgumentError('Draft pesanan harus memiliki minimal satu item.');
    }

    final menuIds = <String>{};

    for (final item in this.items) {
      if (!menuIds.add(item.menuId)) {
        throw ArgumentError(
          'Menu yang sama tidak boleh muncul lebih dari sekali dalam draft.',
        );
      }
    }
  }

  /// Mengambil snapshot keranjang tanpa mengubah atau mengosongkannya.
  factory OrderDraft.fromCart(CartState cart) {
    final stallId = cart.stallId;

    if (cart.isEmpty || stallId == null) {
      throw ArgumentError(
        'Keranjang kosong tidak dapat dijadikan draft pesanan.',
      );
    }

    return OrderDraft(
      stallId: stallId,
      items: [
        for (final item in cart.items)
          OrderDraftItem(
            menuId: item.menu.id,
            quantity: item.quantity,
            note: item.note,
          ),
      ],
      orderNote: cart.orderNote,
    );
  }

  final String stallId;
  final List<OrderDraftItem> items;
  final String orderNote;

  int get totalQuantity {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderDraft &&
          other.stallId == stallId &&
          other.orderNote == orderNote &&
          listEquals(other.items, items));

  @override
  int get hashCode => Object.hash(stallId, orderNote, Object.hashAll(items));
}

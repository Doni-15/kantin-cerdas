import 'package:kantin_cerdas/core/utils/collection_equality.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';

/// Keranjang lokal yang berisi pilihan pengguna.
class CartState {
  CartState({List<CartItem> items = const [], this.orderNote = ''})
    : items = List<CartItem>.unmodifiable(items) {
    if (!CustomerInputLimits.validNote(orderNote)) {
      throw ArgumentError('Catatan pesanan maksimal 300 karakter.');
    }
    final menuIds = <String>{};
    final expectedStallId = this.items.isEmpty
        ? null
        : this.items.first.menu.stallId;

    for (final item in this.items) {
      if (item.menu.id.trim().isEmpty || item.menu.stallId.trim().isEmpty) {
        throw ArgumentError(
          'Identitas menu dan stan dalam keranjang wajib terisi.',
        );
      }

      if (!menuIds.add(item.menu.id)) {
        throw ArgumentError('ID menu dalam keranjang tidak boleh duplikat.');
      }

      if (item.menu.stallId != expectedStallId) {
        throw ArgumentError(
          'Satu keranjang hanya boleh berisi menu dari satu stan.',
        );
      }
    }
  }

  final List<CartItem> items;
  final String orderNote;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  int get totalQuantity {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }

  /// Estimasi subtotal dari snapshot harga menu.
  int get totalPrice {
    return items.fold<int>(0, (total, item) => total + item.subtotal);
  }

  String? get stallId {
    return items.isEmpty ? null : items.first.menu.stallId;
  }

  String? get stallName {
    return items.isEmpty ? null : items.first.menu.stallName;
  }

  String? get block {
    return items.isEmpty ? null : items.first.menu.block;
  }

  /// Jumlah yang dipilih pengguna; nol jika menu belum ada di keranjang.
  int quantityOf(String menuId) {
    for (final item in items) {
      if (item.menu.id == menuId) {
        return item.quantity;
      }
    }

    return 0;
  }

  CartState copyWith({List<CartItem>? items, String? orderNote}) {
    return CartState(
      items: items ?? this.items,
      orderNote: orderNote ?? this.orderNote,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartState &&
          other.orderNote == orderNote &&
          listEquals(other.items, items));

  @override
  int get hashCode => Object.hash(orderNote, Object.hashAll(items));
}

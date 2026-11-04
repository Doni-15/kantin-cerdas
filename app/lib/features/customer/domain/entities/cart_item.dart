import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';

/// Menu yang dipilih pengguna beserta jumlah dan catatannya.
class CartItem {
  CartItem({required this.menu, this.quantity = 1, this.note = ''}) {
    if (!CustomerInputLimits.validPrice(menu.price)) {
      throw ArgumentError('Harga menu harus 1 sampai 10.000.000 rupiah.');
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

  final MenuItem menu;
  final int quantity;
  final String note;

  /// Estimasi subtotal dalam rupiah berdasarkan snapshot harga menu.
  int get subtotal => menu.price * quantity;

  CartItem copyWith({int? quantity, String? note}) {
    return CartItem(
      menu: menu,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartItem &&
          other.menu == menu &&
          other.quantity == quantity &&
          other.note == note);

  @override
  int get hashCode => Object.hash(menu, quantity, note);
}

import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';

class CartItem {
  const CartItem({
    required this.menu,
    this.quantity = 1,
    this.note = '',
  });

  final MenuItem menu;
  final int quantity;
  final String note;

  int get subtotal {
    return menu.price * quantity;
  }

  CartItem copyWith({
    int? quantity,
    String? note,
  }) {
    return CartItem(
      menu: menu,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}
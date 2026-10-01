import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';

final cartProvider =
    NotifierProvider<CartController, CartState>(
  CartController.new,
);

class CartState {
  const CartState({
    this.items = const [],
    this.orderNote = '',
  });

  final List<CartItem> items;
  final String orderNote;

  bool get isEmpty {
    return items.isEmpty;
  }

  bool get isNotEmpty {
    return items.isNotEmpty;
  }

  int get totalQuantity {
    return items.fold(
      0,
      (total, item) {
        return total + item.quantity;
      },
    );
  }

  int get totalPrice {
    return items.fold(
      0,
      (total, item) {
        return total + item.subtotal;
      },
    );
  }

  String? get stallId {
    if (items.isEmpty) {
      return null;
    }

    return items.first.menu.stallId;
  }

  String? get stallName {
    if (items.isEmpty) {
      return null;
    }

    return items.first.menu.stallName;
  }

  String? get block {
    if (items.isEmpty) {
      return null;
    }

    return items.first.menu.block;
  }

  int quantityOf(String menuId) {
    for (final item in items) {
      if (item.menu.id == menuId) {
        return item.quantity;
      }
    }

    return 0;
  }

  CartState copyWith({
    List<CartItem>? items,
    String? orderNote,
  }) {
    return CartState(
      items: items ?? this.items,
      orderNote: orderNote ?? this.orderNote,
    );
  }
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  bool addItem(MenuItem menu) {
    // Keranjang hanya boleh berisi satu stan.
    if (state.isNotEmpty &&
        state.stallId != menu.stallId) {
      return false;
    }

    final index = state.items.indexWhere(
      (item) {
        return item.menu.id == menu.id;
      },
    );

    // Menu belum ada.
    if (index == -1) {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(
            menu: menu,
          ),
        ],
      );

      return true;
    }

    // Menu sudah ada, tambah quantity.
    final newItems = [...state.items];

    final currentItem = newItems[index];

    newItems[index] = currentItem.copyWith(
      quantity: currentItem.quantity + 1,
    );

    state = state.copyWith(
      items: newItems,
    );

    return true;
  }

  void decreaseItem(String menuId) {
    final index = state.items.indexWhere(
      (item) {
        return item.menu.id == menuId;
      },
    );

    if (index == -1) {
      return;
    }

    final newItems = [...state.items];
    final currentItem = newItems[index];

    if (currentItem.quantity <= 1) {
      newItems.removeAt(index);
    } else {
      newItems[index] = currentItem.copyWith(
        quantity: currentItem.quantity - 1,
      );
    }

    if (newItems.isEmpty) {
      state = const CartState();
      return;
    }

    state = state.copyWith(
      items: newItems,
    );
  }

  void removeItem(String menuId) {
    final newItems = state.items.where(
      (item) {
        return item.menu.id != menuId;
      },
    ).toList();

    if (newItems.isEmpty) {
      state = const CartState();
      return;
    }

    state = state.copyWith(
      items: newItems,
    );
  }

  void updateItemNote(
    String menuId,
    String note,
  ) {
    final newItems = state.items.map(
      (item) {
        if (item.menu.id == menuId) {
          return item.copyWith(
            note: note,
          );
        }

        return item;
      },
    ).toList();

    state = state.copyWith(
      items: newItems,
    );
  }

  void updateOrderNote(String note) {
    state = state.copyWith(
      orderNote: note,
    );
  }

  void replaceCart(MenuItem menu) {
    state = CartState(
      items: [
        CartItem(
          menu: menu,
        ),
      ],
    );
  }

  void clearCart() {
    state = const CartState();
  }
}
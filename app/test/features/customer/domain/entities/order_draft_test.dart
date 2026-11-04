import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_state.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';

void main() {
  group('OrderDraftItem', () {
    test('menolak ID menu kosong atau hanya whitespace', () {
      for (final menuId in ['', '   ', '\t\n']) {
        expect(
          () => OrderDraftItem(menuId: menuId, quantity: 1),
          throwsArgumentError,
        );
      }
    });

    test('menolak jumlah nol dan negatif', () {
      for (final quantity in [0, -1]) {
        expect(
          () => OrderDraftItem(menuId: 'menu-a', quantity: quantity),
          throwsArgumentError,
        );
      }
    });

    test('mempertahankan ID, jumlah, dan catatan pengguna', () {
      final item = OrderDraftItem(
        menuId: 'menu-a',
        quantity: 2,
        note: '  Tanpa sambal\nSaus dipisah  ',
      );

      expect(item.menuId, 'menu-a');
      expect(item.quantity, 2);
      expect(item.note, '  Tanpa sambal\nSaus dipisah  ');
    });
  });

  group('OrderDraft', () {
    test('menolak ID stan kosong atau hanya whitespace', () {
      for (final stallId in ['', '   ', '\t\n']) {
        expect(
          () => OrderDraft(
            stallId: stallId,
            items: [OrderDraftItem(menuId: 'menu-a', quantity: 1)],
          ),
          throwsArgumentError,
        );
      }
    });

    test('menolak draft tanpa item', () {
      expect(
        () => OrderDraft(stallId: 'stall-a', items: []),
        throwsArgumentError,
      );
    });

    test('menolak ID menu duplikat meskipun catatannya berbeda', () {
      expect(
        () => OrderDraft(
          stallId: 'stall-a',
          items: [
            OrderDraftItem(menuId: 'menu-a', quantity: 1, note: 'Tanpa sambal'),
            OrderDraftItem(menuId: 'menu-a', quantity: 2, note: 'Pedas'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('menyalin list input agar perubahan sumber tidak mengubah draft', () {
      final source = [
        OrderDraftItem(menuId: 'menu-a', quantity: 2),
        OrderDraftItem(menuId: 'menu-b', quantity: 3),
      ];

      final draft = OrderDraft(stallId: 'stall-a', items: source);

      source.clear();

      expect(draft.items, hasLength(2));
      expect(draft.items.map((item) => item.menuId), ['menu-a', 'menu-b']);
      expect(draft.totalQuantity, 5);
    });

    test('list item tidak dapat diubah melalui draft', () {
      final draft = OrderDraft(
        stallId: 'stall-a',
        items: [OrderDraftItem(menuId: 'menu-a', quantity: 1)],
      );

      expect(
        () => draft.items.add(OrderDraftItem(menuId: 'menu-b', quantity: 1)),
        throwsUnsupportedError,
      );

      expect(
        () => draft.items[0] = OrderDraftItem(menuId: 'menu-b', quantity: 2),
        throwsUnsupportedError,
      );

      expect(() => draft.items.clear(), throwsUnsupportedError);

      expect(draft.items.single.menuId, 'menu-a');
      expect(draft.totalQuantity, 1);
    });
  });

  group('OrderDraft.fromCart', () {
    test('menolak keranjang kosong', () {
      expect(() => OrderDraft.fromCart(CartState()), throwsArgumentError);
    });

    test('memetakan pilihan dan catatan tanpa mengosongkan keranjang', () {
      final cart = CartState(
        items: [
          CartItem(
            menu: _menu(id: 'menu-a'),
            quantity: 2,
            note: '  Tanpa sambal  ',
          ),
          CartItem(menu: _menu(id: 'menu-b'), quantity: 3),
        ],
        orderNote: '  Tolong kemas terpisah  ',
      );

      final draft = OrderDraft.fromCart(cart);

      expect(draft.stallId, 'stall-a');
      expect(draft.items, hasLength(2));

      expect(draft.items[0].menuId, 'menu-a');
      expect(draft.items[0].quantity, 2);
      expect(draft.items[0].note, '  Tanpa sambal  ');

      expect(draft.items[1].menuId, 'menu-b');
      expect(draft.items[1].quantity, 3);
      expect(draft.items[1].note, '');

      expect(draft.orderNote, '  Tolong kemas terpisah  ');
      expect(draft.totalQuantity, 5);

      expect(cart.items, hasLength(2));
      expect(cart.totalQuantity, 5);
      expect(cart.orderNote, '  Tolong kemas terpisah  ');
    });

    test('draft tetap sama setelah keranjang diperbarui atau dikosongkan', () {
      var cart = CartState(
        items: [
          CartItem(
            menu: _menu(id: 'menu-a'),
            quantity: 2,
            note: 'Tanpa sambal',
          ),
        ],
        orderNote: 'Catatan awal',
      );

      final draft = OrderDraft.fromCart(cart);

      cart = cart.copyWith(
        items: [cart.items.single.copyWith(quantity: 4, note: 'Tambah sambal')],
        orderNote: 'Catatan baru',
      );

      expect(cart.totalQuantity, 4);
      expect(cart.items.single.note, 'Tambah sambal');
      expect(cart.orderNote, 'Catatan baru');

      expect(draft.totalQuantity, 2);
      expect(draft.items.single.note, 'Tanpa sambal');
      expect(draft.orderNote, 'Catatan awal');

      cart = CartState();

      expect(cart.isEmpty, isTrue);
      expect(draft.items.single.menuId, 'menu-a');
      expect(draft.totalQuantity, 2);
      expect(draft.orderNote, 'Catatan awal');
    });
  });
}

/// Fixture khusus unit test, tidak dipakai sebagai data runtime aplikasi.
MenuItem _menu({required String id}) {
  return MenuItem(
    id: id,
    name: 'Menu uji $id',
    stallId: 'stall-a',
    stallName: 'Stan uji',
    block: 'Blok uji',
    price: 12000,
    waitTime: '',
    description: '',
    category: 'Kategori uji',
    available: true,
  );
}

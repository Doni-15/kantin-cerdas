import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_state.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';

/// Keranjang bertahan di memori saat pengguna berpindah halaman.
final cartProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

/// Mengelola pilihan keranjang lokal milik pelanggan aktif.
class CartController extends Notifier<CartState> {
  String? _customerId;

  @override
  CartState build() {
    _customerId = ref.read(authStateProvider).activeCustomerId;

    ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      if (!ref.mounted || next.isLoading || next.asData == null) {
        return;
      }

      final nextCustomerId = next.activeCustomerId;

      if (nextCustomerId != _customerId) {
        _customerId = nextCustomerId;
        state = CartState();
      }
    });

    return CartState();
  }

  bool get _canMutate {
    if (!ref.mounted || _customerId == null) {
      return false;
    }

    return ref.read(authStateProvider).activeCustomerId == _customerId &&
        !ref.read(customerCheckoutLockedProvider);
  }

  /// Mengembalikan false jika sesi tidak valid, menu tidak tersedia,
  /// atau keranjang berisi pilihan dari stan berbeda.
  bool addItem(MenuItem requestedMenu) {
    if (!_canMutate) {
      return false;
    }
    final menu = _orderableMenu(requestedMenu);
    if (menu == null ||
        state.quantityOf(menu.id) >= CustomerInputLimits.maxQuantity) {
      return false;
    }

    if (state.isNotEmpty && state.stallId != menu.stallId) {
      return false;
    }

    final newItems = [...state.items];
    final index = newItems.indexWhere((item) => item.menu.id == menu.id);

    if (index == -1) {
      newItems.add(CartItem(menu: menu));
    } else {
      final currentItem = newItems[index];

      // Gunakan snapshot katalog terbaru saat aksi dilakukan.
      newItems[index] = CartItem(
        menu: menu,
        quantity: currentItem.quantity + 1,
        note: currentItem.note,
      );
    }

    state = state.copyWith(items: newItems);
    return true;
  }

  void decreaseItem(String menuId) {
    if (!_canMutate) {
      return;
    }

    final index = state.items.indexWhere((item) => item.menu.id == menuId);

    if (index == -1) {
      return;
    }

    final newItems = [...state.items];
    final currentItem = newItems[index];

    if (currentItem.quantity == 1) {
      newItems.removeAt(index);
    } else {
      newItems[index] = currentItem.copyWith(
        quantity: currentItem.quantity - 1,
      );
    }

    state = newItems.isEmpty ? CartState() : state.copyWith(items: newItems);
  }

  void removeItem(String menuId) {
    if (!_canMutate) {
      return;
    }

    final index = state.items.indexWhere((item) => item.menu.id == menuId);

    if (index == -1) {
      return;
    }

    final newItems = [...state.items]..removeAt(index);

    state = newItems.isEmpty ? CartState() : state.copyWith(items: newItems);
  }

  void updateItemNote(String menuId, String note) {
    if (!_canMutate || !CustomerInputLimits.validNote(note)) {
      return;
    }

    final index = state.items.indexWhere((item) => item.menu.id == menuId);

    if (index == -1 || state.items[index].note == note) {
      return;
    }

    final newItems = [...state.items];
    newItems[index] = newItems[index].copyWith(note: note);

    state = state.copyWith(items: newItems);
  }

  void updateOrderNote(String note) {
    if (!_canMutate ||
        !CustomerInputLimits.validNote(note) ||
        state.isEmpty ||
        state.orderNote == note) {
      return;
    }

    state = state.copyWith(orderNote: note);
  }

  /// Mengganti keranjang setelah pengguna menyetujui konfirmasi.
  ///
  /// expectedCart adalah snapshot sebelum dialog dibuka. Konfirmasi lama
  /// ditolak jika isi keranjang atau pemilik sesi sudah berubah.
  bool replaceCart(MenuItem requestedMenu, {required CartState expectedCart}) {
    if (!_canMutate || state != expectedCart) {
      return false;
    }

    final menu = _orderableMenu(requestedMenu);
    if (menu == null) {
      return false;
    }
    state = CartState(items: [CartItem(menu: menu)]);

    return true;
  }

  MenuItem? _orderableMenu(MenuItem requested) {
    final loaded = ref.read(customerCatalogProvider);
    if (loaded.isLoading || loaded.hasError) {
      return null;
    }
    final catalog = loaded.asData?.value;
    final current = catalog?.menuById(requested.id);
    if (catalog == null ||
        current == null ||
        current.stallId != requested.stallId ||
        !catalog.canOrder(current.id)) {
      return null;
    }
    return current;
  }

  /// Hanya controller checkout setelah layanan mengonfirmasi pesanan.
  /// Bypass lock biasa wajib mencocokkan akun, submission, dan snapshot.
  bool completeSubmission({
    required String submissionId,
    required CartState expectedCart,
  }) {
    if (!ref.mounted ||
        _customerId == null ||
        state != expectedCart ||
        ref.read(authStateProvider).activeCustomerId != _customerId) {
      return false;
    }
    final persisted = ref.read(customerCheckoutJournalProvider(_customerId!));
    if (persisted.isLoading ||
        persisted.hasError ||
        persisted.asData?.value?.submissionId != submissionId) {
      return false;
    }
    state = CartState();
    return true;
  }

  /// Mengosongkan pilihan lokal jika snapshot masih sesuai.
  ///
  /// Gunakan snapshot sebelum dialog konfirmasi atau operasi checkout
  /// agar hasil operasi lama tidak menghapus pilihan yang lebih baru.
  bool clearCart({required CartState expectedCart}) {
    if (!_canMutate || state != expectedCart) {
      return false;
    }

    state = CartState();
    return true;
  }
}

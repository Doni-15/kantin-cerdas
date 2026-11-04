import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_providers.dart';

/// Kemampuan adapter, bukan izin role atau bukti koneksi jaringan sedang sehat.
final customerCheckoutConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(customerOrderRepositoryProvider).isCheckoutConfigured;
});

/// Satu snapshot untuk jumlah pada tombol dan pemeriksaan controller.
/// Tidak mengirim request, tidak membuat pesanan, dan tidak mengubah keranjang.
/// Jangan bergantung pada journal lock: snapshot tetap diperlukan setelah begin.
final customerCheckoutReviewProvider =
    Provider<CustomerOrderPriceConfirmation?>((ref) {
      final auth = ref.watch(authStateProvider);
      final user = auth.asData?.value;
      if (auth.isLoading ||
          auth.hasError ||
          user == null ||
          !user.isActive ||
          !user.role.canUseCustomerFeatures ||
          !ref.watch(customerCheckoutConfiguredProvider)) {
        return null;
      }
      final cart = ref.watch(cartProvider);
      final loaded = ref.watch(customerCatalogProvider);
      final catalog = loaded.isLoading || loaded.hasError
          ? null
          : loaded.asData?.value;
      if (cart.isEmpty ||
          catalog == null ||
          cart.items.any(
            (item) =>
                !catalog.canOrder(item.menu.id) ||
                catalog.menuById(item.menu.id)?.stallId != cart.stallId,
          )) {
        return null;
      }
      return CustomerOrderPriceConfirmation(
        draft: OrderDraft.fromCart(cart),
        unitPricesIdr: {
          for (final item in cart.items)
            item.menu.id: catalog.menuById(item.menu.id)!.price,
        },
      );
    });

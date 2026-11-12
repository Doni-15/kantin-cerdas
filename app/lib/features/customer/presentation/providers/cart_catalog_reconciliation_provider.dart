import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';

/// Hasil rekonsiliasi antara isi keranjang lokal dan snapshot katalog terbaru.
class CartCatalogReconciliation {
  const CartCatalogReconciliation({
    required this.isLoadingCatalog,
    required this.hasCatalogError,
    required this.catalogReady,
    required this.currentStall,
    required this.currentMenus,
    required this.pricedMenus,
    required this.isStallOpen,
    required this.hasCompleteCatalogPricing,
    required this.hasUnavailableItems,
    required this.hasPriceChanges,
    required this.reconciledTotalPriceIdr,
    required this.confirmedSubtotalPriceIdr,
    required this.canProceedToCheckout,
  });

  final bool isLoadingCatalog;
  final bool hasCatalogError;
  final bool catalogReady;
  final Stall? currentStall;
  final Map<String, MenuItem> currentMenus;
  final Map<String, MenuItem> pricedMenus;
  final bool isStallOpen;
  final bool hasCompleteCatalogPricing;
  final bool hasUnavailableItems;
  final bool hasPriceChanges;
  final int reconciledTotalPriceIdr;
  final int confirmedSubtotalPriceIdr;
  final bool canProceedToCheckout;
}

final cartCatalogReconciliationProvider = Provider<CartCatalogReconciliation>((
  ref,
) {
  final cart = ref.watch(cartProvider);
  final catalogState = ref.watch(customerCatalogProvider);
  final catalog = catalogState.isLoading || catalogState.hasError
      ? null
      : catalogState.asData?.value;

  Stall? currentStall;
  if (catalog != null && cart.stallId != null) {
    currentStall = catalog.stallById(cart.stallId!);
  }

  final currentMenus = <String, MenuItem>{
    if (currentStall != null)
      for (final menu in currentStall.menus) menu.id: menu,
  };
  final unmodifiableCurrentMenus = Map<String, MenuItem>.unmodifiable(
    currentMenus,
  );

  final catalogReady = catalog != null;
  final isStallOpen = currentStall?.isOpen == true;
  final hasCompleteCatalogPricing =
      currentStall != null &&
      cart.items.every((item) => currentMenus.containsKey(item.menu.id));
  final pricedMenus = hasCompleteCatalogPricing
      ? unmodifiableCurrentMenus
      : const <String, MenuItem>{};

  final hasUnavailableItems = cart.items.any(
    (item) => currentMenus[item.menu.id]?.available != true,
  );

  final hasPriceChanges = cart.items.any((item) {
    final latestMenu = currentMenus[item.menu.id];
    return latestMenu != null && latestMenu.price != item.menu.price;
  });

  final reconciledTotalPriceIdr = cart.items.fold<int>(0, (total, item) {
    final latestPrice = currentMenus[item.menu.id]?.price ?? item.menu.price;
    return total + latestPrice * item.quantity;
  });
  final confirmedSubtotalPriceIdr = hasCompleteCatalogPricing
      ? reconciledTotalPriceIdr
      : cart.totalPrice;

  final canProceedToCheckout =
      cart.isNotEmpty && catalogReady && isStallOpen && !hasUnavailableItems;

  return CartCatalogReconciliation(
    isLoadingCatalog: catalogState.isLoading,
    hasCatalogError: catalogState.hasError,
    catalogReady: catalogReady,
    currentStall: currentStall,
    currentMenus: unmodifiableCurrentMenus,
    pricedMenus: pricedMenus,
    isStallOpen: isStallOpen,
    hasCompleteCatalogPricing: hasCompleteCatalogPricing,
    hasUnavailableItems: hasUnavailableItems,
    hasPriceChanges: hasPriceChanges,
    reconciledTotalPriceIdr: reconciledTotalPriceIdr,
    confirmedSubtotalPriceIdr: confirmedSubtotalPriceIdr,
    canProceedToCheckout: canProceedToCheckout,
  );
});

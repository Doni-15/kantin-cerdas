import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';

import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Kontrol jumlah pilihan lokal pengguna.
///
/// canAdd mempertimbangkan status stan dari widget pemanggil.
/// Pengurangan tetap diizinkan saat penambahan tidak tersedia.
class CartQuantityButton extends ConsumerStatefulWidget {
  const CartQuantityButton({
    super.key,
    required this.menu,
    required this.canAdd,
  });

  final MenuItem menu;
  final bool canAdd;

  @override
  ConsumerState<CartQuantityButton> createState() => _CartQuantityButtonState();
}

class _CartQuantityButtonState extends ConsumerState<CartQuantityButton> {
  bool _dialogOpen = false;

  Future<void> _addItem() async {
    if (_dialogOpen ||
        ref.read(customerCheckoutLockedProvider) ||
        !widget.canAdd ||
        !widget.menu.available) {
      return;
    }

    final customerId = ref.read(authStateProvider).activeCustomerId;

    if (customerId == null) {
      return;
    }

    final loaded = ref.read(customerCatalogProvider);
    if (loaded.isLoading ||
        loaded.hasError ||
        loaded.asData?.value.canOrder(widget.menu.id) != true) {
      KcSnackBar.info(
        context,
        'Ketersediaan menu belum dapat dipastikan. Muat ulang katalog.',
      );
      return;
    }
    final requestedMenu = widget.menu;
    final controller = ref.read(cartProvider.notifier);

    if (controller.addItem(requestedMenu)) {
      return;
    }

    final expectedCart = ref.read(cartProvider);

    // Penolakan selain perbedaan stan tidak membuka dialog penggantian.
    if (expectedCart.isEmpty || expectedCart.stallId == requestedMenu.stallId) {
      KcSnackBar.info(
        context,
        'Menu tidak dapat ditambah. Maksimal 99 per menu; periksa ketersediaannya.',
      );
      return;
    }

    setState(() => _dialogOpen = true);

    try {
      final replace = await showKcRoleDialog<bool>(
        context: context,
        ref: ref,
        role: UserRole.customer,
        builder: (dialogContext) {
          return AlertDialog(
            scrollable: true,
            title: const Text('Ganti isi keranjang?'),
            content: Text(
              'Keranjang berisi menu dari ${expectedCart.stallName}. '
              'Untuk menambahkan ${requestedMenu.name} dari '
              '${requestedMenu.stallName}, isi keranjang saat ini '
              'akan diganti.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Ganti keranjang'),
              ),
            ],
          );
        },
      );

      if (!mounted || replace != true) {
        return;
      }

      if (ref.read(authStateProvider).activeCustomerId != customerId ||
          widget.menu.id != requestedMenu.id ||
          widget.menu.stallId != requestedMenu.stallId) {
        return;
      }

      // Gunakan properti widget terbaru setelah menunggu dialog.
      if (!widget.canAdd || !widget.menu.available) {
        KcSnackBar.info(context, 'Menu ini sedang tidak dapat ditambahkan.');
        return;
      }

      final replaced = ref
          .read(cartProvider.notifier)
          .replaceCart(widget.menu, expectedCart: expectedCart);

      if (!replaced) {
        KcSnackBar.info(
          context,
          'Keranjang telah berubah. Coba tambahkan menu lagi.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _dialogOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerId = ref.watch(
      authStateProvider.select((auth) => auth.activeCustomerId),
    );

    if (customerId == null) {
      return const SizedBox.shrink();
    }

    final checkoutLocked = ref.watch(customerCheckoutLockedProvider);
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final quantity = cart.quantityOf(widget.menu.id);
    final loaded = ref.watch(customerCatalogProvider);
    final itemCanBeAdded =
        widget.canAdd &&
        !loaded.isLoading &&
        !loaded.hasError &&
        loaded.asData?.value.canOrder(widget.menu.id) == true;
    final atLimit = quantity >= CustomerInputLimits.maxQuantity;
    final canIncrease =
        itemCanBeAdded && !_dialogOpen && !atLimit && !checkoutLocked;

    if (quantity == 0) {
      if (!itemCanBeAdded) {
        return Text(
          'Tidak tersedia',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      }

      return OutlinedButton.icon(
        onPressed: canIncrease ? _addItem : null,
        icon: const Icon(Icons.add),
        label: Text(checkoutLocked ? 'Periksa pesanan' : 'Tambah'),
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: KcSpacing.xs,
      runSpacing: KcSpacing.xs,
      children: [
        IconButton.outlined(
          tooltip: 'Kurangi jumlah ${widget.menu.name}',
          onPressed: _dialogOpen || checkoutLocked
              ? null
              : () {
                  ref.read(cartProvider.notifier).decreaseItem(widget.menu.id);
                },
          icon: const Icon(Icons.remove),
        ),
        Semantics(
          liveRegion: true,
          label: 'Jumlah ${widget.menu.name}',
          value: '$quantity',
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: KcSpacing.lg),
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge,
              ),
            ),
          ),
        ),
        IconButton.outlined(
          tooltip: atLimit
              ? 'Maksimal 99 per menu'
              : 'Tambah jumlah ${widget.menu.name}',
          onPressed: canIncrease ? _addItem : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/session_restore_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_catalog_reconciliation_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart/cart_footer.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart/cart_item_card.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart/cart_notice.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart/empty_cart.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/customer_checkout_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/listen_customer_checkout_result.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Pilihan keranjang lokal pengguna yang direkonsiliasi terhadap katalog aktif.
class CustomerCartPage extends ConsumerStatefulWidget {
  const CustomerCartPage({super.key});

  @override
  ConsumerState<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends ConsumerState<CustomerCartPage> {
  final _orderNoteController = TextEditingController();
  bool _clearing = false;

  @override
  void initState() {
    super.initState();

    ref.listenManual<String>(cartProvider.select((cart) => cart.orderNote), (
      _,
      note,
    ) {
      if (_orderNoteController.text != note) {
        _orderNoteController.value = TextEditingValue(
          text: note,
          selection: TextSelection.collapsed(offset: note.length),
        );
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _orderNoteController.dispose();
    super.dispose();
  }

  void _goBack() {
    FocusScope.of(context).unfocus();

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.customerHome);
    }
  }

  Future<void> _clearCart() async {
    if (_clearing) {
      return;
    }

    final customerId = ref.read(authStateProvider).activeCustomerId;
    if (customerId == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    final expectedCart = ref.read(cartProvider);
    if (expectedCart.isEmpty) {
      return;
    }

    setState(() => _clearing = true);

    try {
      final confirmed = await showKcRoleDialog<bool>(
        context: context,
        ref: ref,
        role: UserRole.customer,
        builder: (dialogContext) {
          return AlertDialog(
            scrollable: true,
            title: const Text('Kosongkan keranjang?'),
            content: Text(
              '${expectedCart.totalQuantity} item dari '
              '${expectedCart.stallName} beserta catatannya '
              'akan dihapus dari keranjang.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Kosongkan'),
              ),
            ],
          );
        },
      );

      if (!mounted || confirmed != true) {
        return;
      }

      if (ref.read(authStateProvider).activeCustomerId != customerId) {
        return;
      }

      final cleared = ref
          .read(cartProvider.notifier)
          .clearCart(expectedCart: expectedCart);

      if (!cleared) {
        KcSnackBar.info(
          context,
          'Keranjang telah berubah. Periksa kembali sebelum mengosongkan.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  void _continueToConfirmation() {
    if (_clearing ||
        ref.read(authStateProvider).activeCustomerId == null ||
        ref.read(cartProvider).isEmpty) {
      return;
    }

    final reconciliation = ref.read(cartCatalogReconciliationProvider);
    if (!reconciliation.canProceedToCheckout) {
      KcSnackBar.info(
        context,
        'Periksa kembali ketersediaan menu sebelum melanjutkan.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.push(Routes.customerOrderConfirmation);
  }

  @override
  Widget build(BuildContext context) {
    final customerId = ref.watch(
      authStateProvider.select((auth) => auth.activeCustomerId),
    );

    if (customerId == null) {
      return const SessionRestorePage();
    }

    listenCustomerCheckoutResult(context, ref);
    final checkoutLocked = ref.watch(customerCheckoutLockedProvider);
    if (checkoutLocked) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _goBack),
          title: const Text('Keranjang'),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const SingleChildScrollView(
                padding: EdgeInsets.all(KcSpacing.pageHorizontal),
                child: CustomerCheckoutPanel(),
              ),
            ),
          ),
        ),
      );
    }
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    final appBar = AppBar(
      leading: BackButton(onPressed: _goBack),
      title: const Text('Keranjang'),
      actions: [
        if (cart.isNotEmpty)
          IconButton(
            tooltip: 'Kosongkan keranjang',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearing ? null : _clearCart,
          ),
      ],
    );

    if (cart.isEmpty) {
      return Scaffold(
        appBar: appBar,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const EmptyCart(),
            ),
          ),
        ),
      );
    }

    final reconciliation = ref.watch(cartCatalogReconciliationProvider);
    final canContinue = !_clearing && reconciliation.canProceedToCheckout;
    final stallName = cart.stallName;
    final block = cart.block;

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: KcSpacing.pageHorizontal,
                vertical: KcSpacing.lg,
              ),
              itemCount: cart.items.length + 2,
              findChildIndexCallback: (key) {
                if (key == ValueKey('header:$customerId')) {
                  return 0;
                }

                if (key == ValueKey('order-note:$customerId')) {
                  return cart.items.length + 1;
                }

                for (var i = 0; i < cart.items.length; i++) {
                  if (key ==
                      ValueKey('item:$customerId:${cart.items[i].menu.id}')) {
                    return i + 1;
                  }
                }

                return null;
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    key: ValueKey('header:$customerId'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (stallName != null)
                        Semantics(
                          header: true,
                          child: Text(
                            stallName,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      if (block != null && block.trim().isNotEmpty) ...[
                        const SizedBox(height: KcSpacing.xs),
                        Text(
                          block,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: KcSpacing.md),
                      if (reconciliation.isLoadingCatalog)
                        const CartNotice(
                          message: 'Memperbarui informasi menu...',
                          loading: true,
                        )
                      else if (reconciliation.hasCatalogError)
                        CartNotice(
                          message:
                              'Informasi menu belum dapat diperbarui. '
                              'Muat ulang untuk melanjutkan.',
                          onRetry: () =>
                              ref.invalidate(customerCatalogProvider),
                        )
                      else if (reconciliation.currentStall == null)
                        CartNotice(
                          message:
                              'Stan tidak ditemukan dalam katalog yang dimuat.',
                          onRetry: () =>
                              ref.invalidate(customerCatalogProvider),
                        )
                      else if (!reconciliation.isStallOpen)
                        const CartNotice(
                          message:
                              'Stan sedang tutup. Kamu masih bisa '
                              'mengurangi jumlah atau menghapus pilihan.',
                        )
                      else if (reconciliation.hasUnavailableItems)
                        const CartNotice(
                          message:
                              'Ada menu yang belum tersedia untuk dipesan. '
                              'Sesuaikan isi keranjang untuk melanjutkan.',
                        ),
                      if (reconciliation.hasPriceChanges)
                        const CartNotice(
                          message:
                              'Sebagian harga menu berubah. '
                              'Periksa harga terbaru pada tahap konfirmasi.',
                        ),
                      const SizedBox(height: KcSpacing.sm),
                    ],
                  );
                }

                if (index == cart.items.length + 1) {
                  return Padding(
                    key: ValueKey('order-note:$customerId'),
                    padding: const EdgeInsets.only(top: KcSpacing.sm),
                    child: KcTextField(
                      label: 'Catatan pesanan (opsional)',
                      hint: 'Tulis permintaan tambahan',
                      controller: _orderNoteController,
                      maxLength: CustomerInputLimits.maxNoteLength,
                      enabled: !_clearing,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      onChanged: (note) {
                        ref.read(cartProvider.notifier).updateOrderNote(note);
                      },
                    ),
                  );
                }

                final item = cart.items[index - 1];
                final latestMenu = reconciliation.currentMenus[item.menu.id];

                return CartItemCard(
                  key: ValueKey('item:$customerId:${item.menu.id}'),
                  item: item,
                  latestMenu: latestMenu,
                  enabled: !_clearing,
                  canAdd:
                      !_clearing &&
                      reconciliation.isStallOpen &&
                      latestMenu?.available == true,
                  unavailable:
                      reconciliation.catalogReady &&
                      (!reconciliation.isStallOpen ||
                          latestMenu == null ||
                          !latestMenu.available),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : CartFooter(
              cart: cart,
              reconciledTotalPriceIdr: reconciliation.reconciledTotalPriceIdr,
              onContinue: canContinue ? _continueToConfirmation : null,
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/customer/application/customer_cart_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_checkout_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_cart_item_card.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_cart_item_note_dialog.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_cart_summary_bar.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerCartPage extends ConsumerStatefulWidget {
  const CustomerCartPage({
    super.key,
    required this.accountId,
    this.onOrderCompleted,
  });

  final String accountId;
  final ValueChanged<String>? onOrderCompleted;

  @override
  ConsumerState<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends ConsumerState<CustomerCartPage> {
  final _generalNoteCtrl = TextEditingController();
  String? _lastSyncedGeneralNote;
  var _busy = false;

  @override
  void dispose() {
    _generalNoteCtrl.dispose();
    super.dispose();
  }

  void _syncGeneralNoteController(CustomerCart cart) {
    if (_lastSyncedGeneralNote != cart.generalNote) {
      _generalNoteCtrl.text = cart.generalNote;
      _lastSyncedGeneralNote = cart.generalNote;
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      showCustomerSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal memperbarui keranjang.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editItemNote(CustomerCartItem item) async {
    final updatedNote = await showCustomerCartItemNoteDialog(context, item);
    if (!mounted || updatedNote == null || updatedNote == item.itemNote) return;
    await _mutate(
      () => ref
          .read(customerCartControllerProvider)
          .updateItem(
            accountId: widget.accountId,
            itemId: item.id,
            quantity: item.quantity,
            itemNote: updatedNote,
          ),
    );
  }

  Future<void> _proceedToCheckout(CustomerCart currentCart) async {
    var cart = currentCart;
    final typedNote = _generalNoteCtrl.text.trim();
    if (typedNote != cart.generalNote) {
      await _mutate(() async {
        cart = await ref
            .read(customerCartControllerProvider)
            .setGeneralNote(
              accountId: widget.accountId,
              generalNote: typedNote,
            );
        _lastSyncedGeneralNote = cart.generalNote;
      });
    }
    if (!mounted || !cart.canCheckout) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerCheckoutPage(
          accountId: widget.accountId,
          initialCart: cart,
          onOrderCompleted: widget.onOrderCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(customerCartProvider(widget.accountId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          if (cartAsync.asData?.value.isEmpty == false)
            IconButton(
              tooltip: 'Hapus Semua',
              onPressed: _busy
                  ? null
                  : () async {
                      final confirmed = await showCustomerConfirmDialog(
                        context,
                        title: 'Kosongkan keranjang?',
                        message: 'Seluruh item dalam keranjang akan dihapus.',
                        confirmLabel: 'Kosongkan',
                        destructive: true,
                      );
                      if (!confirmed || !mounted) return;
                      await _mutate(
                        () => ref
                            .read(customerCartControllerProvider)
                            .clear(accountId: widget.accountId),
                      );
                    },
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: cartAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => CustomerErrorView(
            error: error,
            fallback: 'Keranjang tidak dapat dimuat.',
            onRetry: () =>
                ref.invalidate(customerCartProvider(widget.accountId)),
          ),
          data: (cart) {
            _syncGeneralNoteController(cart);
            if (cart.isEmpty) {
              return CustomerEmptyView(
                icon: Icons.shopping_cart_outlined,
                title: 'Keranjang masih kosong',
                subtitle: 'Tambahkan menu dari salah satu kantin.',
                action: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Jelajahi Kantin'),
                ),
              );
            }
            return _buildFilledCart(context, cart);
          },
        ),
      ),
    );
  }

  Widget _buildFilledCart(BuildContext context, CustomerCart cart) {
    final theme = Theme.of(context);
    final stall = cart.stall;
    final hasPriceChange = cart.blockers.contains(
      CustomerCartBlocker.hasPriceChange,
    );

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(customerCartControllerProvider)
                .refresh(widget.accountId),
            child: ListView(
              padding: const EdgeInsets.all(KcSpacing.md),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (stall != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(KcSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_outlined),
                          const SizedBox(width: KcSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stall.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  'Lokasi: Blok ${stall.block}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CustomerStatusChip.openClosed(
                            context,
                            isOpen: stall.isOpen,
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final blocker in cart.blockers)
                  Container(
                    margin: const EdgeInsets.only(top: KcSpacing.xs),
                    padding: const EdgeInsets.all(KcSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(KcRadius.small),
                    ),
                    child: Text(
                      blocker.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                if (hasPriceChange) ...[
                  const SizedBox(height: KcSpacing.xs),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _mutate(
                            () => ref
                                .read(customerCartControllerProvider)
                                .acknowledgePrices(
                                  accountId: widget.accountId,
                                  expectedVersion: cart.draftVersion,
                                ),
                          ),
                    icon: const Icon(Icons.price_check),
                    label: const Text('Setujui Harga Terbaru'),
                  ),
                ],
                const SizedBox(height: KcSpacing.md),
                for (final item in cart.items)
                  CustomerCartItemCard(
                    accountId: widget.accountId,
                    item: item,
                    busy: _busy,
                    canIncrement:
                        item.isOrderable && (stall?.canAcceptOrders ?? false),
                    onDecrement: () => _mutate(
                      () => ref
                          .read(customerCartControllerProvider)
                          .updateItem(
                            accountId: widget.accountId,
                            itemId: item.id,
                            quantity: item.quantity - 1,
                          ),
                    ),
                    onIncrement: () => _mutate(
                      () => ref
                          .read(customerCartControllerProvider)
                          .updateItem(
                            accountId: widget.accountId,
                            itemId: item.id,
                            quantity: item.quantity + 1,
                          ),
                    ),
                    onRemove: () => _mutate(
                      () => ref
                          .read(customerCartControllerProvider)
                          .deleteItem(
                            accountId: widget.accountId,
                            itemId: item.id,
                          ),
                    ),
                    onEditNote: () => _editItemNote(item),
                  ),
                const SizedBox(height: KcSpacing.sm),
                TextField(
                  controller: _generalNoteCtrl,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan pesanan (opsional)',
                    hintText: 'Catatan umum untuk kantin',
                  ),
                ),
                const SizedBox(height: KcSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => _mutate(() async {
                            final saved = await ref
                                .read(customerCartControllerProvider)
                                .setGeneralNote(
                                  accountId: widget.accountId,
                                  generalNote: _generalNoteCtrl.text.trim(),
                                );
                            _lastSyncedGeneralNote = saved.generalNote;
                            if (context.mounted) {
                              showCustomerSnackBar(
                                context,
                                'Catatan pesanan disimpan.',
                              );
                            }
                          }),
                    child: const Text('Simpan Catatan'),
                  ),
                ),
              ],
            ),
          ),
        ),
        CustomerCartSummaryBar(
          subtotal: cart.subtotal,
          canCheckout: cart.canCheckout,
          busy: _busy,
          onCheckout: () => _proceedToCheckout(cart),
        ),
      ],
    );
  }
}

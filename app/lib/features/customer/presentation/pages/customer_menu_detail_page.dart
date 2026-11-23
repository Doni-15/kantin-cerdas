import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/customer/application/customer_cart_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_cart_action_button.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_menu_detail_widgets.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerMenuDetailPage extends ConsumerStatefulWidget {
  const CustomerMenuDetailPage({
    super.key,
    required this.accountId,
    required this.menuId,
    this.initialMenuName,
    this.onOrderCompleted,
  });

  final String accountId;
  final String menuId;
  final String? initialMenuName;
  final ValueChanged<String>? onOrderCompleted;

  @override
  ConsumerState<CustomerMenuDetailPage> createState() =>
      _CustomerMenuDetailPageState();
}

class _CustomerMenuDetailPageState
    extends ConsumerState<CustomerMenuDetailPage> {
  final _noteCtrl = TextEditingController();
  var _quantity = 1;
  var _submitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(CustomerMenuDetailBundle bundle) async {
    if (_submitting ||
        !bundle.stall.canAcceptOrders ||
        !bundle.menu.isAvailable) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(customerCartControllerProvider)
          .addItem(
            accountId: widget.accountId,
            menuId: bundle.menu.id,
            quantity: _quantity,
            itemNote: _noteCtrl.text.trim(),
          );
      if (!mounted) return;
      showCustomerSnackBar(
        context,
        '${bundle.menu.name} (${_quantity}x) masuk keranjang.',
      );
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'CART_DIFFERENT_STALL') {
        setState(() => _submitting = false);
        final replace = await showCustomerConfirmDialog(
          context,
          title: 'Ganti isi keranjang?',
          message:
              'Keranjang berisi item dari kantin lain. Ganti seluruh isi keranjang dengan menu dari ${bundle.stall.name}?',
          confirmLabel: 'Ganti Keranjang',
        );
        if (!mounted || !replace) return;
        setState(() => _submitting = true);
        try {
          await ref
              .read(customerCartControllerProvider)
              .addItem(
                accountId: widget.accountId,
                menuId: bundle.menu.id,
                quantity: _quantity,
                itemNote: _noteCtrl.text.trim(),
                replaceStall: true,
              );
          if (!mounted) return;
          showCustomerSnackBar(
            context,
            'Keranjang diganti & ${bundle.menu.name} ditambahkan.',
          );
          Navigator.of(context).pop();
        } catch (err) {
          if (!mounted) return;
          showCustomerSnackBar(
            context,
            presentAppError(err, fallback: 'Gagal mengganti keranjang.'),
          );
        }
      } else {
        showCustomerSnackBar(
          context,
          presentAppError(error, fallback: 'Gagal menambahkan item.'),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (accountId: widget.accountId, menuId: widget.menuId);
    final detailAsync = ref.watch(customerMenuDetailProvider(key));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detailAsync.asData?.value.menu.name ??
              widget.initialMenuName ??
              'Detail Menu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          CustomerCartAppBarButton(
            accountId: widget.accountId,
            onOpenedCartOrder: widget.onOrderCompleted,
          ),
        ],
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => CustomerErrorView(
            error: error,
            fallback: 'Detail menu tidak dapat dimuat.',
            onRetry: () => ref.invalidate(customerMenuDetailProvider(key)),
          ),
          data: (bundle) {
            final theme = Theme.of(context);
            final menu = bundle.menu;
            final stall = bundle.stall;
            final photoBytes = menu.hasPhoto
                ? ref.watch(customerMenuPhotoProvider(key)).asData?.value
                : null;
            final canOrder = stall.canAcceptOrders && menu.isAvailable;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(KcSpacing.md),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(KcRadius.card),
                        child: SizedBox(
                          height: 196,
                          width: double.infinity,
                          child: Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: photoBytes != null
                                ? Image.memory(
                                    photoBytes,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.restaurant_outlined,
                                      size: 48,
                                    ),
                                  )
                                : const Icon(
                                    Icons.restaurant_outlined,
                                    size: 48,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: KcSpacing.md),
                      Text(menu.name, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        '${menu.categoryName} · ${stall.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: KcSpacing.xs),
                      Wrap(
                        spacing: KcSpacing.sm,
                        runSpacing: KcSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            formatRupiah(menu.price),
                            style: theme.textTheme.titleLarge,
                          ),
                          CustomerStatusChip.availability(
                            context,
                            isAvailable: menu.isAvailable,
                          ),
                        ],
                      ),
                      if (menu.description.isNotEmpty) ...[
                        const SizedBox(height: KcSpacing.sm),
                        Text(
                          menu.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (!stall.ownerActive)
                        const CustomerMenuStatusNotice(
                          text: 'Kantin sementara tidak menerima pesanan.',
                          isError: true,
                        )
                      else if (!stall.isOpen)
                        const CustomerMenuStatusNotice(
                          text:
                              'Kantin sedang tutup sehingga menu belum dapat dipesan.',
                        )
                      else if (!menu.isAvailable)
                        const CustomerMenuStatusNotice(
                          text: 'Menu ini sedang berstatus Habis.',
                          isError: true,
                        ),
                      const SizedBox(height: KcSpacing.md),
                      const Divider(),
                      const SizedBox(height: KcSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Jumlah',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: 'Kurangi jumlah',
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: KcSpacing.sm,
                            ),
                            child: Text(
                              '$_quantity',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: 'Tambah jumlah',
                            onPressed: _quantity < 999
                                ? () => setState(() => _quantity++)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: KcSpacing.md),
                      TextField(
                        controller: _noteCtrl,
                        maxLength: 300,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Catatan item (opsional)',
                          hintText: 'Contoh: Tidak pakai sambal',
                        ),
                      ),
                    ],
                  ),
                ),
                CustomerMenuOrderBottomBar(
                  totalAmount: menu.price * _quantity,
                  canOrder: canOrder,
                  submitting: _submitting,
                  onSubmit: () => _submit(bundle),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_state.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/order_confirmation_notice.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OrderConfirmationHeader extends StatelessWidget {
  const OrderConfirmationHeader({
    super.key,
    required this.cart,
    required this.stall,
    required this.loading,
    required this.hasError,
    required this.hasCatalogPricing,
    required this.onRetry,
    required this.onEdit,
  });
  final CartState cart;
  final Stall? stall;
  final bool loading;
  final bool hasError;
  final bool hasCatalogPricing;
  final VoidCallback onRetry;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Stan pilihan', style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: KcSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(KcSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: KcSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stall?.name ?? cart.stallName ?? '',
                        style: theme.textTheme.titleMedium,
                      ),
                      if ((stall?.block ?? cart.block ?? '').trim().isNotEmpty)
                        Text(stall?.block ?? cart.block ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: KcSpacing.md),
        if (loading)
          const OrderConfirmationNotice(
            message: 'Memperbarui informasi menu...',
            loading: true,
          )
        else if (hasError)
          OrderConfirmationNotice(
            message:
                'Informasi menu belum dapat diperbarui. Estimasi memakai harga yang tersimpan di keranjang.',
            onRetry: onRetry,
          )
        else if (!hasCatalogPricing)
          OrderConfirmationNotice(
            message:
                'Sebagian pilihan tidak ditemukan dalam katalog. Periksa kembali keranjang.',
            onRetry: onRetry,
          ),
        if (stall?.isOpen == false)
          const OrderConfirmationNotice(message: 'Stan pilihan sedang tutup.'),
        const SizedBox(height: KcSpacing.md),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: KcSpacing.xs,
          children: [
            Semantics(
              header: true,
              child: Text('Pilihanmu', style: theme.textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ubah keranjang'),
            ),
          ],
        ),
        const SizedBox(height: KcSpacing.sm),
      ],
    );
  }
}

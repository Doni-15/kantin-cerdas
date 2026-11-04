import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_state.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/customer_checkout_panel.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OrderConfirmationSummary extends StatelessWidget {
  const OrderConfirmationSummary({
    super.key,
    required this.cart,
    required this.estimatedSubtotal,
    required this.hasCatalogPricing,
  });
  final CartState cart;
  final int estimatedSubtotal;
  final bool hasCatalogPricing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cart.orderNote.trim().isNotEmpty) ...[
          const SizedBox(height: KcSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(KcSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catatan pesanan', style: theme.textTheme.titleSmall),
                  const SizedBox(height: KcSpacing.xs),
                  Text(cart.orderNote),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: KcSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(KcSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  spacing: KcSpacing.md,
                  overflowSpacing: KcSpacing.xs,
                  children: [
                    Text(
                      'Estimasi subtotal · ${cart.totalQuantity} item',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      formatRupiah(estimatedSubtotal),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: KcSpacing.xs),
                Text(
                  hasCatalogPricing
                      ? 'Estimasi berdasarkan informasi menu yang tersedia.'
                      : 'Estimasi memakai harga yang tersimpan di keranjang.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: KcSpacing.md),
        const CustomerCheckoutPanel(allowSubmission: true),
      ],
    );
  }
}

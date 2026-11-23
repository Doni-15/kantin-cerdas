import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerCartSummaryBar extends StatelessWidget {
  const CustomerCartSummaryBar({
    super.key,
    required this.subtotal,
    required this.canCheckout,
    required this.busy,
    required this.onCheckout,
  });

  final int subtotal;
  final bool canCheckout;
  final bool busy;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(KcSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KcSpacing.sm,
            runSpacing: 4,
            children: [
              Text('Subtotal', style: theme.textTheme.titleMedium),
              Text(formatRupiah(subtotal), style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bayar tunai saat mengambil pesanan di kantin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KcSpacing.sm),
          FilledButton(
            onPressed: canCheckout && !busy ? onCheckout : null,
            child: const Text('Lanjut ke Checkout'),
          ),
        ],
      ),
    );
  }
}

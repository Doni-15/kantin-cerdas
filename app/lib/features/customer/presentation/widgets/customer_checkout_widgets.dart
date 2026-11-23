import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_inline_progress_indicator.dart';

class CustomerCheckoutItemRow extends StatelessWidget {
  const CustomerCheckoutItemRow({super.key, required this.item});

  final CustomerCartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantity}x ${item.menuName}',
                style: theme.textTheme.bodyLarge,
              ),
              if (item.itemNote.isNotEmpty)
                Text(
                  'Catatan: ${item.itemNote}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          formatRupiah(item.lineTotal),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class CustomerCheckoutUncertainBanner extends StatelessWidget {
  const CustomerCheckoutUncertainBanner({
    super.key,
    required this.message,
    required this.busy,
    required this.onVerify,
  });

  final String message;
  final bool busy;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: KcSpacing.md),
      padding: const EdgeInsets.all(KcSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KcRadius.small),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: KcSpacing.xs),
          OutlinedButton(
            onPressed: busy ? null : onVerify,
            child: const Text('Periksa Status Pesanan'),
          ),
        ],
      ),
    );
  }
}

class CustomerCheckoutBottomBar extends StatelessWidget {
  const CustomerCheckoutBottomBar({
    super.key,
    required this.totalAmount,
    required this.canCheckout,
    required this.submitting,
    required this.onSubmit,
  });

  final int totalAmount;
  final bool canCheckout;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KcSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: KcSpacing.sm,
        runSpacing: KcSpacing.xs,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Tunai', style: theme.textTheme.bodySmall),
              Text(
                formatRupiah(totalAmount),
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          FilledButton(
            onPressed: canCheckout && !submitting ? onSubmit : null,
            child: submitting
                ? const KcInlineProgressIndicator()
                : const Text('Kirim Pesanan'),
          ),
        ],
      ),
    );
  }
}

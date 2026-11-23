import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_inline_progress_indicator.dart';

class CustomerMenuStatusNotice extends StatelessWidget {
  const CustomerMenuStatusNotice({
    super.key,
    required this.text,
    this.isError = false,
  });

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: KcSpacing.sm),
      padding: const EdgeInsets.all(KcSpacing.sm),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KcRadius.small),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isError ? scheme.onErrorContainer : scheme.onSurface,
        ),
      ),
    );
  }
}

class CustomerMenuOrderBottomBar extends StatelessWidget {
  const CustomerMenuOrderBottomBar({
    super.key,
    required this.totalAmount,
    required this.canOrder,
    required this.submitting,
    required this.onSubmit,
  });

  final int totalAmount;
  final bool canOrder;
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
              Text('Total', style: theme.textTheme.bodySmall),
              Text(
                formatRupiah(totalAmount),
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          FilledButton(
            onPressed: canOrder && !submitting ? onSubmit : null,
            child: submitting
                ? const KcInlineProgressIndicator()
                : const Text('Tambah ke Keranjang'),
          ),
        ],
      ),
    );
  }
}

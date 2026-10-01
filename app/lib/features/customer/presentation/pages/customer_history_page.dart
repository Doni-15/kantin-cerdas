import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerHistoryPage extends StatelessWidget {
  const CustomerHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          KcSpacing.pageHorizontal,
          KcSpacing.lg,
          KcSpacing.pageHorizontal,
          KcSpacing.lg,
        ),
        children: [
          Text(
            'Riwayat pesanan',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: KcSpacing.xs),
          Text(
            'Pesanan yang sudah selesai bisa kamu lihat kembali di sini.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: KcSpacing.lg),
          Text('September', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: KcSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(KcSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: KcSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesanan KC-019',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '3 Sep · 1 porsi',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KcSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: KcStatusColors.of(context).successContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Selesai',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: KcStatusColors.of(context).success,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KcSpacing.md),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: KcSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: KcSpacing.xs),
                      Expanded(
                        child: Text(
                          'Tunai diterima',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        'Rp18.000',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

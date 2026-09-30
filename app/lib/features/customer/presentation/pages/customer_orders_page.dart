import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColors = KcStatusColors.of(context);

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
            'Pesanan aktif',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: KcSpacing.xs),
          Text(
            'Pantau pesananmu sampai siap diambil.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: KcSpacing.lg),
          Container(
            padding: const EdgeInsets.all(KcSpacing.md),
            decoration: BoxDecoration(
              color: statusColors.warningContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hourglass_top_rounded, color: statusColors.warning),
                const SizedBox(width: KcSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menunggu konfirmasi',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: statusColors.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kantin sedang meninjau pesananmu. Pembayaran dilakukan tunai saat mengambil.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KcSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(KcSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'KC-027',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '12.05',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KcSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined, color: colors.primary),
                      const SizedBox(width: KcSpacing.xs),
                      Expanded(
                        child: Text(
                          'Dapur Bu Rina · Blok A',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KcSpacing.md),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: KcSpacing.md),
                  _OrderProgress(
                    title: 'Pesanan dibuat',
                    detail: '2 porsi · 12.05',
                    isComplete: true,
                    isLast: false,
                  ),
                  _OrderProgress(
                    title: 'Menunggu konfirmasi',
                    detail: 'Pesanan sedang ditinjau kantin',
                    isActive: true,
                    isLast: false,
                  ),
                  _OrderProgress(
                    title: 'Siap diambil',
                    detail: 'Bayar tunai di kantin',
                    isLast: true,
                  ),
                  const SizedBox(height: KcSpacing.md),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: KcSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total pesanan',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        'Rp30.000',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: KcSpacing.xs),
                  Text(
                    'Tunai saat mengambil',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
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

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({
    required this.title,
    required this.detail,
    this.isComplete = false,
    this.isActive = false,
    required this.isLast,
  });

  final String title;
  final String detail;
  final bool isComplete;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColors = KcStatusColors.of(context);
    final markerColor = isComplete || isActive
        ? statusColors.warning
        : colors.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Icon(
                  isComplete
                      ? Icons.check_circle
                      : isActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: markerColor,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isComplete
                          ? statusColors.warning.withValues(alpha: 0.5)
                          : colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: KcSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: KcSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
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

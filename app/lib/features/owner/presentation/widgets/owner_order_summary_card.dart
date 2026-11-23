import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_formatters.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderSummaryCard extends StatelessWidget {
  const OwnerOrderSummaryCard({super.key, required this.summary});

  final OwnerOrderSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.orderNumber,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: KcSpacing.xs),
                OwnerStatusBadge.forOrderStatus(context, summary.status),
              ],
            ),
            const SizedBox(height: KcSpacing.xs),
            Text(
              'Pelanggan: ${summary.customerName}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Dibuat: ${formatOrderTime(summary.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (summary.prepEstimateMinutes != null &&
                summary.prepEstimateMinutes! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Estimasi persiapan: ${summary.prepEstimateMinutes} menit (informatif)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: KcSpacing.xs),
            Text(
              'Pembayaran: Tunai · ${summary.paymentStatus.label}',
              style: theme.textTheme.titleSmall,
            ),
            if (summary.statusReason != null &&
                summary.statusReason!.isNotEmpty) ...[
              const SizedBox(height: KcSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(KcSpacing.sm),
                  child: Text(
                    'Alasan: ${summary.statusReason}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerApplicationStatusCard extends StatelessWidget {
  const CustomerApplicationStatusCard({
    super.key,
    required this.application,
    required this.hasActiveOrders,
    this.onResubmit,
  });

  final OwnerApplication application;
  final bool hasActiveOrders;
  final VoidCallback? onResubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRejected = application.status == OwnerApplicationStatus.ditolak;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status Pengajuan: ${application.status.label}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('Rencana kantin: ${application.plannedStallName}'),
            Text('Lokasi: ${application.plannedLocation}'),
            const SizedBox(height: 4),
            Text(
              'Dikirim: ${formatCustomerTimestamp(application.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isRejected && application.rejectionReason != null) ...[
              const SizedBox(height: KcSpacing.xs),
              Container(
                padding: const EdgeInsets.all(KcSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(KcRadius.small),
                ),
                child: Text(
                  'Alasan penolakan: ${application.rejectionReason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            if (hasActiveOrders &&
                application.status ==
                    OwnerApplicationStatus.menungguReview) ...[
              const SizedBox(height: KcSpacing.xs),
              Text(
                'Catatan: Anda saat ini masih memiliki pesanan aktif. Admin akan memeriksa status pesanan aktif saat meninjau pengajuan.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onResubmit != null) ...[
              const SizedBox(height: KcSpacing.sm),
              FilledButton.tonal(
                onPressed: onResubmit,
                child: const Text('Ajukan Kembali'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerActiveCountsCard extends StatelessWidget {
  const OwnerActiveCountsCard({
    super.key,
    required this.counts,
    required this.onSelectStatus,
  });

  final OwnerActiveCounts counts;
  final ValueChanged<OwnerOrderStatus> onSelectStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _CountSegment(
              label: 'Menunggu',
              count: counts.menungguKonfirmasi,
              onTap: () => onSelectStatus(OwnerOrderStatus.menungguKonfirmasi),
            ),
            const VerticalDivider(width: 1),
            _CountSegment(
              label: 'Diproses',
              count: counts.diproses,
              onTap: () => onSelectStatus(OwnerOrderStatus.diproses),
            ),
            const VerticalDivider(width: 1),
            _CountSegment(
              label: 'Siap',
              count: counts.siapDiambil,
              onTap: () => onSelectStatus(OwnerOrderStatus.siapDiambil),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountSegment extends StatelessWidget {
  const _CountSegment({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: KcSpacing.sm,
            horizontal: KcSpacing.xs,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$count', style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

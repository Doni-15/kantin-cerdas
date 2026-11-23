import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrderTimelineRow extends StatelessWidget {
  const CustomerOrderTimelineRow({super.key, required this.event});

  final CustomerOrderEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
        const SizedBox(width: KcSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.toStatus.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (event.reason != null && event.reason!.isNotEmpty)
                Text(event.reason!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Text(
          formatCustomerTimestamp(event.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class CustomerOrderSnapshotItemRow extends StatelessWidget {
  const CustomerOrderSnapshotItemRow({super.key, required this.item});

  final CustomerOrderItem item;

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
              Text(
                '@ ${formatRupiah(item.unitPrice)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (item.itemNote.isNotEmpty)
                Text(
                  'Catatan: ${item.itemNote}',
                  style: theme.textTheme.bodySmall,
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

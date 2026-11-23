import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_formatters.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerAttentionOrderTile extends StatelessWidget {
  const OwnerAttentionOrderTile({
    super.key,
    required this.order,
    required this.onTap,
  });

  final OwnerOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.orderNumber,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(width: KcSpacing.xs),
                      Flexible(
                        child: Text(
                          '· ${order.customerName}',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.itemSummary} · ${formatRupiah(context, order.totalAmount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  OwnerStatusBadge.forOrderStatus(context, order.status),
                ],
              ),
            ),
            const SizedBox(width: KcSpacing.xs),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

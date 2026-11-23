import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_formatters.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderRowTile extends StatelessWidget {
  const OwnerOrderRowTile({
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
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatOrderTime(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.itemSummary} · ${formatRupiah(context, order.totalAmount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: KcSpacing.xs,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OwnerStatusBadge.forOrderStatus(context, order.status),
                      Text(
                        'Tunai · ${order.paymentStatus.label}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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

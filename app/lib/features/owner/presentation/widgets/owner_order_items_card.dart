import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_formatters.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderItemsCard extends StatelessWidget {
  const OwnerOrderItemsCard({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  final List<OwnerOrderItemSnapshot> items;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(KcSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${items[i].quantity}x ${items[i].menuName}',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          '@ ${formatRupiah(context, items[i].unitPrice)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (items[i].itemNote.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan item: ${items[i].itemNote}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    formatRupiah(context, items[i].lineTotal),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(KcSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Tunai',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: KcSpacing.xs),
                Text(
                  formatRupiah(context, totalAmount),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

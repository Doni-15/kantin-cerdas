import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_photo_thumb.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerCartItemCard extends StatelessWidget {
  const CustomerCartItemCard({
    super.key,
    required this.accountId,
    required this.item,
    required this.busy,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
    required this.onEditNote,
  });

  final String accountId;
  final CustomerCartItem item;
  final bool busy;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: KcSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomerMediaThumb(
                  accountId: accountId,
                  targetId: item.menuItemId,
                  isStall: false,
                  hasPhoto: item.hasPhoto,
                  size: 52,
                ),
                const SizedBox(width: KcSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.menuName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      if (item.priceChanged)
                        Text(
                          'Harga berubah: ${formatRupiah(item.seenUnitPrice)} → ${formatRupiah(item.currentUnitPrice)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          formatRupiah(item.currentUnitPrice),
                          style: theme.textTheme.bodyMedium,
                        ),
                      if (item.isArchived || !item.isAvailable) ...[
                        const SizedBox(height: 4),
                        CustomerStatusChip.availability(
                          context,
                          isAvailable: item.isAvailable,
                          isArchived: item.isArchived,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus item',
                  onPressed: busy ? null : onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: busy ? null : onEditNote,
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: Text(
                        item.itemNote.isEmpty
                            ? 'Tambah catatan'
                            : item.itemNote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KcSpacing.xs),
                IconButton.outlined(
                  tooltip: 'Kurangi item',
                  onPressed: busy ? null : onDecrement,
                  icon: const Icon(Icons.remove, size: 18),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KcSpacing.xs),
                  child: Text(
                    '${item.quantity}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Tambah item',
                  onPressed: !busy && canIncrement ? onIncrement : null,
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

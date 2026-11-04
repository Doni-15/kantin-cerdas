import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OrderReviewItem extends StatelessWidget {
  const OrderReviewItem({
    super.key,
    required this.item,
    required this.currentMenu,
  });

  final CartItem item;
  final MenuItem? currentMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitPrice = currentMenu?.price ?? item.menu.price;
    final subtotal = unitPrice * item.quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: KcSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantity} × ${item.menu.name}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: KcSpacing.xs),
              Text('${formatRupiah(unitPrice)} per item'),
              const SizedBox(height: KcSpacing.xs),
              Text(
                'Estimasi ${formatRupiah(subtotal)}',
                style: theme.textTheme.titleSmall,
              ),
              if (item.note.trim().isNotEmpty) ...[
                const SizedBox(height: KcSpacing.sm),
                Text('Catatan: ${item.note}'),
              ],
              if (currentMenu?.available == false) ...[
                const SizedBox(height: KcSpacing.xs),
                Text(
                  'Menu sedang tidak tersedia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

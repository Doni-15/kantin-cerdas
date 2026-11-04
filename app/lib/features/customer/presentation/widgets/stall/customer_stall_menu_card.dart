import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/cart_quantity_button.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerStallMenuCard extends StatelessWidget {
  const CustomerStallMenuCard({
    super.key,
    required this.menu,
    required this.isStallOpen,
  });
  final MenuItem menu;
  final bool isStallOpen;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KcEntityImage.thumbnail(
                  imageUrl: menu.imageUrl,
                  width: 64,
                  height: 64,
                  fallbackIcon: Icons.restaurant_outlined,
                ),
                const SizedBox(width: KcSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(menu.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: KcSpacing.xs),
                      Text(
                        formatRupiah(menu.price),
                        style: theme.textTheme.titleSmall,
                      ),
                      if (menu.description.trim().isNotEmpty) ...[
                        const SizedBox(height: KcSpacing.xs),
                        Text(menu.description),
                      ],
                      if (menu.waitTime.trim().isNotEmpty) ...[
                        const SizedBox(height: KcSpacing.xs),
                        Text(menu.waitTime, style: theme.textTheme.bodySmall),
                      ],
                      if (!isStallOpen || !menu.available) ...[
                        const SizedBox(height: KcSpacing.xs),
                        Text(
                          !isStallOpen
                              ? 'Stan sedang tutup'
                              : 'Sedang tidak tersedia',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: CartQuantityButton(
                menu: menu,
                canAdd: isStallOpen && menu.available,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/presentation/mappers/owner_labels.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerMenuCard extends StatelessWidget {
  const OwnerMenuCard({
    super.key,
    required this.menu,
    required this.onEdit,
    required this.onDelete,
  });
  final OwnerMenu menu;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KcEntityImage.thumbnail(
                  imageUrl: menu.imageUrl,
                  width: 56,
                  height: 56,
                  fallbackIcon: Icons.restaurant_outlined,
                ),
                const SizedBox(width: KcSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: KcSpacing.xs),
                      Text(formatRupiah(menu.priceIdr)),
                      if (menu.description.isNotEmpty) ...[
                        const SizedBox(height: KcSpacing.xs / 2),
                        Text(menu.description),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.sm),
            Wrap(
              spacing: KcSpacing.xs,
              runSpacing: KcSpacing.xs,
              children: [
                Chip(label: Text(ownerCategoryLabel(menu.category))),
                Chip(label: Text(menu.isAvailable ? 'Tersedia' : 'Habis')),
              ],
            ),
            Wrap(
              spacing: KcSpacing.xs,
              runSpacing: KcSpacing.xs,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

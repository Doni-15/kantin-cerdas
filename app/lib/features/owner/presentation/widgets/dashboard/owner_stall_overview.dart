import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerStallOverview extends StatelessWidget {
  const OwnerStallOverview({super.key, required this.stall});
  final OwnerStall stall;
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
                  imageUrl: stall.imageUrl,
                  width: 56,
                  height: 56,
                  fallbackIcon: Icons.storefront_outlined,
                ),
                const SizedBox(width: KcSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stall.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(stall.block),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.sm),
            Text(
              stall.isOpen ? 'Stan buka' : 'Stan tutup',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text('Estimasi persiapan: ${stall.prepTimeMin} menit'),
            const SizedBox(height: KcSpacing.md),
            Wrap(
              spacing: KcSpacing.xs,
              runSpacing: KcSpacing.xs,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go(Routes.ownerOrders),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Lihat pesanan'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(Routes.ownerCanteen),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Kelola menu'),
                ),
                TextButton.icon(
                  onPressed: () => context.push(Routes.ownerStallSettings),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Pengaturan stan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

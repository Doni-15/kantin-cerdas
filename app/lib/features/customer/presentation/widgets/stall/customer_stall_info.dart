import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerStallInfo extends StatelessWidget {
  const CustomerStallInfo({super.key, required this.stall});

  final Stall stall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                KcEntityImage.avatar(
                  imageUrl: stall.imageUrl,
                  radius: 28,
                  fallbackIcon: Icons.storefront_outlined,
                ),
                const SizedBox(width: KcSpacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      stall.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KcSpacing.sm,
                vertical: KcSpacing.xs / 2,
              ),
              decoration: BoxDecoration(
                color: stall.isOpen
                    ? colors.primaryContainer
                    : colors.surfaceContainer,
                borderRadius: BorderRadius.circular(KcRadius.pill),
              ),
              child: Text(
                stall.isOpen ? 'Buka' : 'Tutup',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: stall.isOpen
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            if (stall.block.trim().isNotEmpty) ...[
              const SizedBox(height: KcSpacing.sm),
              Text('Lokasi: ${stall.block}'),
            ],
            if (stall.waitTime.trim().isNotEmpty) ...[
              const SizedBox(height: KcSpacing.xs),
              Text('Estimasi waktu: ${stall.waitTime}'),
            ],
            if (stall.description.trim().isNotEmpty) ...[
              const SizedBox(height: KcSpacing.md),
              Text(stall.description),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerDraftStallCard extends StatelessWidget {
  const OwnerDraftStallCard({
    super.key,
    required this.stall,
    required this.onContinueSetup,
  });

  final OwnerStall stall;
  final VoidCallback onContinueSetup;

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
              children: [
                Expanded(
                  child: Text(stall.name, style: theme.textTheme.titleLarge),
                ),
                OwnerStatusBadge.forStallOpen(
                  context,
                  isListed: false,
                  isOpen: false,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${stall.campus} · ${stall.block}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KcSpacing.sm),
            Text(
              'Kantin masih berstatus draf dan belum tampil ke pelanggan.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: KcSpacing.md),
            FilledButton(
              onPressed: onContinueSetup,
              child: const Text('Lanjutkan Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerPublishedStallCard extends StatelessWidget {
  const OwnerPublishedStallCard({
    super.key,
    required this.stall,
    required this.togglingOpen,
    required this.onToggleOpen,
  });

  final OwnerStall stall;
  final bool togglingOpen;
  final VoidCallback onToggleOpen;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stall.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        '${stall.campus} · ${stall.block}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stall.waitMinutes > 0
                            ? 'Diterbitkan · Estimasi ${stall.waitMinutes} menit'
                            : 'Diterbitkan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KcSpacing.xs),
                OwnerStatusBadge.forStallOpen(
                  context,
                  isListed: stall.isListed,
                  isOpen: stall.isOpen,
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.md),
            SizedBox(
              width: double.infinity,
              child: stall.isOpen
                  ? OutlinedButton.icon(
                      onPressed: togglingOpen ? null : onToggleOpen,
                      icon: const Icon(Icons.pause_circle_outline),
                      label: const Text('Tutup Kantin'),
                    )
                  : FilledButton.icon(
                      onPressed: togglingOpen ? null : onToggleOpen,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Buka Kantin'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

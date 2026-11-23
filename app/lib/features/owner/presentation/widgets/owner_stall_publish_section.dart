import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerStallPublishSection extends StatelessWidget {
  const OwnerStallPublishSection({
    super.key,
    required this.stall,
    required this.eligibility,
    required this.busy,
    required this.onPublishStall,
    required this.onOpenMenusTab,
    required this.onToggleOpen,
  });

  final OwnerStall stall;
  final OwnerPublishEligibility eligibility;
  final bool busy;
  final VoidCallback onPublishStall;
  final VoidCallback onOpenMenusTab;
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
              children: [
                Expanded(
                  child: Text(
                    'Status Publikasi & Operasional',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                OwnerStatusBadge.forStallOpen(
                  context,
                  isListed: stall.isListed,
                  isOpen: stall.isOpen,
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.sm),
            if (!stall.isListed) ...[
              Text(
                eligibility.canPublish
                    ? 'Semua prasyarat terpenuhi. Setelah diterbitkan, kantin mulai dalam status Tutup dan dapat dibuka secara manual.'
                    : 'Syarat terbit: profil wajib lengkap dan minimal 1 menu Tersedia (saat ini: ${eligibility.availableMenuCount} menu tersedia).',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: KcSpacing.sm),
              Wrap(
                spacing: KcSpacing.xs,
                runSpacing: KcSpacing.xs,
                children: [
                  FilledButton(
                    onPressed: (!busy && eligibility.canPublish)
                        ? onPublishStall
                        : null,
                    child: const Text('Terbitkan Kantin'),
                  ),
                  if (eligibility.availableMenuCount == 0)
                    OutlinedButton(
                      onPressed: onOpenMenusTab,
                      child: const Text('Siapkan Menu'),
                    ),
                ],
              ),
            ] else ...[
              Text(
                'Kantin sudah diterbitkan. Gunakan Buka/Tutup untuk mengatur penerimaan pesanan baru.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: KcSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(stall.isOpen ? 'Kantin Buka' : 'Kantin Tutup'),
                subtitle: const Text('Kontrol manual oleh Owner.'),
                value: stall.isOpen,
                onChanged: busy ? null : (_) => onToggleOpen(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

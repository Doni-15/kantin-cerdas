import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_status_pills.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';

class AdminStallRow extends ConsumerWidget {
  const AdminStallRow({
    super.key,
    required this.accountId,
    required this.stall,
    required this.onTap,
  });

  final String accountId;
  final AdminStallSummary stall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColors = KcStatusColors.of(context);
    final photo = stall.hasPhoto
        ? ref
              .watch(
                adminStallPhotoProvider((
                  accountId: accountId,
                  stallId: stall.id,
                )),
              )
              .asData
              ?.value
        : null;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          color: theme.colorScheme.surfaceContainerHighest,
          child: photo != null
              ? Image.memory(photo, fit: BoxFit.cover)
              : const Icon(Icons.storefront_outlined),
        ),
      ),
      title: Text(stall.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Owner: ${stall.ownerName}'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              AdminStatusPill(
                label: stall.isListed ? 'Diterbitkan' : 'Belum Terbit',
                foreground: stall.isListed
                    ? statusColors.info
                    : theme.colorScheme.onSurfaceVariant,
                background: stall.isListed
                    ? statusColors.infoContainer
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              if (stall.isListed)
                AdminStatusPill(
                  label: stall.isOpen ? 'Buka' : 'Tutup',
                  foreground: stall.isOpen
                      ? statusColors.success
                      : theme.colorScheme.onSurfaceVariant,
                  background: stall.isOpen
                      ? statusColors.successContainer
                      : theme.colorScheme.surfaceContainerHighest,
                ),
              if (!stall.ownerIsActive)
                AdminStatusPill(
                  label: 'Owner Nonaktif',
                  foreground: theme.colorScheme.onErrorContainer,
                  background: theme.colorScheme.errorContainer,
                ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

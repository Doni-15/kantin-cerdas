import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_formatters.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerMenuListRow extends ConsumerWidget {
  const OwnerMenuListRow({
    super.key,
    required this.accountId,
    required this.item,
    required this.onTap,
    this.onToggleAvailability,
  });

  final String accountId;
  final OwnerMenuItem item;
  final VoidCallback onTap;
  final VoidCallback? onToggleAvailability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColors = KcStatusColors.of(context);
    final photo = item.hasPhoto
        ? ref
              .watch(
                ownerMenuPhotoProvider((accountId: accountId, menuId: item.id)),
              )
              .asData
              ?.value
        : null;
    final statusText = item.isArchived
        ? 'Diarsipkan'
        : item.isAvailable
        ? 'Tersedia'
        : 'Habis';
    final statusColor = item.isArchived
        ? theme.colorScheme.onSurfaceVariant
        : item.isAvailable
        ? statusColors.success
        : theme.colorScheme.error;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KcRadius.small),
              child: Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHighest,
                child: photo == null
                    ? Icon(
                        Icons.fastfood_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : Image.memory(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.fastfood_outlined),
                      ),
              ),
            ),
            const SizedBox(width: KcSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${item.categoryName} · ${formatRupiah(context, item.price)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onToggleAvailability != null)
              Switch(
                value: item.isAvailable,
                onChanged: (_) => onToggleAvailability!(),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

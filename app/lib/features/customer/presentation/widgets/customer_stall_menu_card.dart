import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_photo_thumb.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_inline_progress_indicator.dart';

class CustomerStallMenuCard extends StatelessWidget {
  const CustomerStallMenuCard({
    super.key,
    required this.accountId,
    required this.menu,
    required this.canAdd,
    required this.adding,
    required this.onTapCard,
    required this.onTapAdd,
  });

  final String accountId;
  final CustomerMenuSummary menu;
  final bool canAdd;
  final bool adding;
  final VoidCallback onTapCard;
  final VoidCallback onTapAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTapCard,
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomerMediaThumb(
                accountId: accountId,
                targetId: menu.id,
                isStall: false,
                hasPhoto: menu.hasPhoto,
                size: 64,
              ),
              const SizedBox(width: KcSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(menu.price),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (menu.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        menu.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    CustomerStatusChip.availability(
                      context,
                      isAvailable: menu.isAvailable,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KcSpacing.xs),
              FilledButton.tonal(
                onPressed: canAdd && !adding ? onTapAdd : null,
                child: adding
                    ? const KcInlineProgressIndicator(size: 16)
                    : const Text('Tambah'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

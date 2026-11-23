import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/kc_formatters.dart';
import 'package:kantin_cerdas/features/ai/domain/ai_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_menu_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_photo_thumb.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_status_badge.dart';

class AiRecommendationCard extends StatelessWidget {
  const AiRecommendationCard({
    super.key,
    required this.accountId,
    required this.item,
    this.onOrderCompleted,
  });

  final String accountId;
  final AiMenuRecommendation item;
  final ValueChanged<String>? onOrderCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<KcStatusColors>();

    final Color badgeFg;
    final Color badgeBg;
    if (item.isOrderable) {
      badgeFg = statusColors?.success ?? theme.colorScheme.primary;
      badgeBg =
          statusColors?.successContainer ?? theme.colorScheme.primaryContainer;
    } else if (item.unavailableReason == 'owner_inactive') {
      badgeFg = theme.colorScheme.error;
      badgeBg = theme.colorScheme.errorContainer;
    } else {
      badgeFg = theme.colorScheme.onSurfaceVariant;
      badgeBg = theme.colorScheme.surfaceContainerHighest;
    }

    return Card(
      margin: const EdgeInsets.only(top: KcSpacing.xs),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomerMediaThumb(
                  accountId: accountId,
                  targetId: item.id,
                  isStall: false,
                  hasPhoto: item.hasPhoto,
                  size: 56,
                ),
                const SizedBox(width: KcSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.stall.name} · ${item.stall.block}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(item.price),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: KcSpacing.xs,
                runSpacing: KcSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  KcStatusBadge(
                    label: item.availabilityLabel,
                    foreground: badgeFg,
                    background: badgeBg,
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CustomerMenuDetailPage(
                            accountId: accountId,
                            menuId: item.id,
                            initialMenuName: item.name,
                            onOrderCompleted: onOrderCompleted,
                          ),
                        ),
                      );
                    },
                    child: const Text('Lihat Detail'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

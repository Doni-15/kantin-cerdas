import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerHomeSearchPrompt extends StatelessWidget {
  const CustomerHomeSearchPrompt({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(KcRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(KcRadius.control),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KcSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KcRadius.control),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: KcSpacing.sm),
              Expanded(
                child: Text(
                  'Cari makanan atau kantin...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerStallCard extends StatelessWidget {
  const CustomerStallCard({
    super.key,
    required this.stall,
    required this.onTap,
  });

  final CustomerStallSummary stall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(KcRadius.small),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: KcSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stall.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Blok ${stall.block}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: KcSpacing.xs,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CustomerStatusChip.openClosed(
                          context,
                          isOpen: stall.isOpen,
                        ),
                        if (stall.waitMinutes > 0)
                          Text(
                            '± ${stall.waitMinutes} menit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerHomeSkeletonList extends StatelessWidget {
  const CustomerHomeSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: KcSpacing.xs),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(KcRadius.card),
            ),
          ),
      ],
    );
  }
}

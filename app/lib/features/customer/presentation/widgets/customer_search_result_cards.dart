import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerSearchStallCard extends StatelessWidget {
  const CustomerSearchStallCard({
    super.key,
    required this.stall,
    required this.onTap,
  });

  final CatalogStall stall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: KcSpacing.xs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.storefront_outlined),
              const SizedBox(width: KcSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stall.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Blok ${stall.block}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomerStatusChip.openClosed(
                      context,
                      isOpen: stall.isOpen,
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

class CustomerSearchMenuCard extends StatelessWidget {
  const CustomerSearchMenuCard({
    super.key,
    required this.menu,
    required this.onTap,
  });

  final CatalogMenuItem menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: KcSpacing.xs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.restaurant_outlined),
              const SizedBox(width: KcSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${menu.stallName} · ${formatRupiah(menu.price)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: KcSpacing.xs,
                      runSpacing: 4,
                      children: [
                        CustomerStatusChip.availability(
                          context,
                          isAvailable: menu.isAvailable,
                        ),
                        CustomerStatusChip.openClosed(
                          context,
                          isOpen: menu.stallIsOpen,
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

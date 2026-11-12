import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_catalog.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerSearchResultsSliver extends StatelessWidget {
  const CustomerSearchResultsSliver({
    super.key,
    required this.catalog,
    required this.query,
    required this.maxPrice,
    required this.onlyAvailable,
  });

  final CustomerCatalog catalog;
  final String query;
  final int? maxPrice;
  final bool onlyAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceLimit = maxPrice;

    final menus = catalog.menus
        .where((menu) {
          final matchesQuery =
              menu.name.toLowerCase().contains(query) ||
              menu.stallName.toLowerCase().contains(query);

          final matchesPrice = priceLimit == null || menu.price <= priceLimit;

          final matchesAvailability =
              !onlyAvailable || catalog.canOrder(menu.id);

          return matchesQuery && matchesPrice && matchesAvailability;
        })
        .toList(growable: false);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: KcSpacing.pageHorizontal),
      sliver: SliverList.builder(
        itemCount: menus.isEmpty ? 2 : menus.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: KcSpacing.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${menus.length} menu ditemukan',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          if (menus.isEmpty) {
            return KcStatusPanel(
              icon: Icons.search_off,
              title: catalog.menus.isEmpty
                  ? 'Belum ada menu'
                  : 'Menu tidak ditemukan',
              message: catalog.menus.isEmpty
                  ? 'Menu akan ditampilkan saat tersedia.'
                  : 'Coba ubah kata pencarian atau filter.',
            );
          }

          final menu = menus[index - 1];

          return Padding(
            padding: const EdgeInsets.only(bottom: KcSpacing.sm),
            child: Card(
              child: ListTile(
                leading: KcEntityImage.thumbnail(
                  imageUrl: menu.imageUrl,
                  width: 48,
                  height: 48,
                  fallbackIcon: Icons.restaurant_outlined,
                ),
                title: Text(menu.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(menu.stallName),
                    const SizedBox(height: KcSpacing.xs / 2),
                    Text(
                      formatRupiah(menu.price),
                      style: theme.textTheme.labelLarge,
                    ),
                    if (menu.waitTime.trim().isNotEmpty) Text(menu.waitTime),
                    if (!catalog.canOrder(menu.id))
                      Text(
                        catalog.stallById(menu.stallId)?.isOpen == true
                            ? 'Sedang tidak tersedia'
                            : 'Stan sedang tutup',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  context.push(Routes.customerStallLocation(menu.stallId));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

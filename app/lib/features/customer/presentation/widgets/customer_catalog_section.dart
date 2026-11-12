import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_catalog.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_catalog_message.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Isi katalog pada halaman utama.
class CustomerCatalogSection extends ConsumerWidget {
  const CustomerCatalogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(customerCatalogProvider);

    return catalogState.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const KcLoadingSkeleton(
        label: 'Memuat katalog',
        layout: KcSkeletonLayout.catalog,
      ),
      error: (error, _) => _CatalogMessage(
        icon: Icons.cloud_off_outlined,
        title: customerCatalogErrorTitle(error),
        message: customerCatalogErrorMessage(error),
        action: KcButton(
          label: 'Coba lagi',
          onPressed: () => ref.invalidate(customerCatalogProvider),
        ),
      ),
      data: (catalog) => _CatalogContent(
        catalog: catalog,
        onRefresh: () => ref.invalidate(customerCatalogProvider),
      ),
    );
  }
}

class _CatalogContent extends StatefulWidget {
  const _CatalogContent({required this.catalog, required this.onRefresh});

  final CustomerCatalog catalog;
  final VoidCallback onRefresh;

  @override
  State<_CatalogContent> createState() => _CatalogContentState();
}

class _CatalogContentState extends State<_CatalogContent> {
  String? _selectedCategory;

  @override
  void didUpdateWidget(covariant _CatalogContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectedCategory = _selectedCategory;

    if (selectedCategory != null &&
        !widget.catalog.menus.any(
          (menu) =>
              widget.catalog.canOrder(menu.id) &&
              menu.category == selectedCategory,
        )) {
      _selectedCategory = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final availableMenus = widget.catalog.menus
        .where((menu) => widget.catalog.canOrder(menu.id))
        .toList(growable: false);

    final categories =
        availableMenus
            .map((menu) => menu.category)
            .where((category) => category.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final visibleMenus = availableMenus.where(
      (menu) => _selectedCategory == null || menu.category == _selectedCategory,
    );

    final openStalls = widget.catalog.stalls.where((stall) => stall.isOpen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: KcSpacing.xs,
          runSpacing: KcSpacing.xs,
          children: [
            Semantics(
              header: true,
              child: Text('Menu tersedia', style: theme.textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat ulang'),
            ),
          ],
        ),
        const SizedBox(height: KcSpacing.sm),
        if (categories.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = null);
                    }
                  },
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(left: KcSpacing.xs),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: KcSpacing.sm),
        ],
        if (availableMenus.isEmpty)
          const _CatalogMessage(
            icon: Icons.restaurant_menu,
            title: 'Belum ada menu tersedia',
            message: 'Menu yang tersedia akan ditampilkan di sini.',
          )
        else
          for (final menu in visibleMenus)
            Padding(
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
                  subtitle: Text(
                    '${menu.stallName}\n${formatRupiah(menu.price)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(Routes.customerStallLocation(menu.stallId)),
                ),
              ),
            ),
        const SizedBox(height: KcSpacing.lg),
        Semantics(
          header: true,
          child: Text('Stan yang buka', style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: KcSpacing.sm),
        if (openStalls.isEmpty)
          const _CatalogMessage(
            icon: Icons.storefront_outlined,
            title: 'Belum ada stan yang buka',
            message: 'Stan yang sedang buka akan ditampilkan di sini.',
          )
        else
          for (final stall in openStalls)
            Padding(
              padding: const EdgeInsets.only(bottom: KcSpacing.sm),
              child: Card(
                child: ListTile(
                  leading: KcEntityImage.thumbnail(
                    imageUrl: stall.imageUrl,
                    width: 48,
                    height: 48,
                    fallbackIcon: Icons.storefront_outlined,
                  ),
                  title: Text(stall.name),
                  subtitle: stall.block.trim().isEmpty
                      ? null
                      : Text(stall.block),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(Routes.customerStallLocation(stall.id)),
                ),
              ),
            ),
      ],
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.lg),
          child: Column(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: KcSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: KcSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: KcSpacing.md),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

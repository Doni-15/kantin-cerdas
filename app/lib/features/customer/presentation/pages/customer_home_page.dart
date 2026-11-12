import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_logo.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_catalog_section.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Layout halaman utama pelanggan.
///
/// Data katalog dikelola oleh CustomerCatalogSection melalui Riverpod.
/// Scaffold dan navigasi bawah disediakan oleh CustomerShell.
class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: KcSpacing.pageHorizontal,
            vertical: KcSpacing.lg,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const KcLogo(size: 24),
                          const SizedBox(width: KcSpacing.xs),
                          Text(
                            'KantinCerdas',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: KcSpacing.xs),
                      Semantics(
                        header: true,
                        child: Text(
                          'Mau makan apa hari ini?',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KcSpacing.sm),
                IconButton(
                  tooltip: 'Buka keranjang',
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () => context.push(Routes.customerCart),
                ),
                IconButton(
                  tooltip: 'Buka profil',
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => context.go(Routes.customerProfile),
                ),
              ],
            ),
            const SizedBox(height: KcSpacing.lg),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                alignment: AlignmentDirectional.centerStart,
              ),
              onPressed: () => context.push(Routes.customerSearch),
              icon: const Icon(Icons.search),
              label: const Text('Cari menu atau stan'),
            ),
            const SizedBox(height: KcSpacing.lg),
            const CustomerCatalogSection(),
          ],
        ),
      ),
    );
  }
}

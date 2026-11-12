import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_page_body.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_stall_section.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/menu/owner_menu_browser.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerCanteenPage extends StatelessWidget {
  const OwnerCanteenPage({super.key});
  @override
  Widget build(BuildContext context) {
    return OwnerPageBody(
      title: 'Menu kantin',
      description: 'Kelola menu, harga, dan ketersediaan.',
      child: OwnerStallSection(
        builder: (stall) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(stall.name, style: Theme.of(context).textTheme.titleLarge),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(Routes.ownerStallSettings),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Pengaturan stan'),
              ),
            ),
            const SizedBox(height: KcSpacing.sm),
            OwnerMenuBrowser(key: ValueKey(stall.id), stallId: stall.id),
          ],
        ),
      ),
    );
  }
}

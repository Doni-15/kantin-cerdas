import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KcSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: KcSpacing.md),
          Text(
            'Keranjangmu masih kosong',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: KcSpacing.xs),
          const Text(
            'Pilih menu dari stan yang kamu inginkan.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KcSpacing.lg),
          KcButton(
            label: 'Cari menu',
            onPressed: () => context.push(Routes.customerSearch),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_formatters.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerArchivedMenuDetailView extends ConsumerWidget {
  const OwnerArchivedMenuDetailView({
    super.key,
    required this.accountId,
    required this.menu,
    required this.busy,
    required this.onRestore,
  });

  final String accountId;
  final OwnerMenuItem menu;
  final bool busy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photo = menu.hasPhoto
        ? ref
              .watch(
                ownerMenuPhotoProvider((accountId: accountId, menuId: menu.id)),
              )
              .asData
              ?.value
        : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Menu Arsip')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KcSpacing.md),
          children: [
            if (photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(photo, height: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: KcSpacing.md),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(KcSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      '${menu.categoryName} · ${formatRupiah(context, menu.price)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Status: Diarsipkan (${menu.isAvailable ? 'Tersedia' : 'Habis'})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (menu.description.isNotEmpty) ...[
                      const SizedBox(height: KcSpacing.sm),
                      Text(menu.description),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            FilledButton.icon(
              onPressed: busy ? null : onRestore,
              icon: const Icon(Icons.unarchive_outlined),
              label: const Text('Pulihkan Menu'),
            ),
          ],
        ),
      ),
    );
  }
}

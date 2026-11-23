import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_category_sheet.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerCategoriesPage extends ConsumerWidget {
  const OwnerCategoriesPage({super.key, required this.accountId});

  final String accountId;

  Future<void> _openCategorySheet(
    BuildContext context, {
    required List<OwnerCategory> existing,
    OwnerCategory? editing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => OwnerCategorySheet(
        accountId: accountId,
        existing: existing,
        editing: editing,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(ownerCategoriesProvider(accountId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Menu')),
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const OwnerLoadingView(message: 'Memuat kategori…'),
          error: (error, _) => OwnerErrorView(
            error: error,
            onRetry: () => ref.invalidate(ownerCategoriesProvider(accountId)),
          ),
          data: (categories) => RefreshIndicator(
            onRefresh: () =>
                ref.refresh(ownerCategoriesProvider(accountId).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(KcSpacing.md),
              children: [
                Text(
                  '${categories.length} kategori',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KcSpacing.sm),
                if (categories.isEmpty)
                  const OwnerEmptyView(
                    icon: Icons.category_outlined,
                    title: 'Belum ada kategori',
                    description:
                        'Tambahkan kategori untuk mengelompokkan menu.',
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < categories.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            title: Text(categories[i].name),
                            subtitle: Text(
                              categories[i].archivedMenuCount > 0
                                  ? '${categories[i].activeMenuCount} aktif · ${categories[i].archivedMenuCount} arsip'
                                  : '${categories[i].activeMenuCount} menu',
                            ),
                            trailing: IconButton(
                              tooltip: 'Ubah ${categories[i].name}',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openCategorySheet(
                                context,
                                existing: categories,
                                editing: categories[i],
                              ),
                            ),
                            onTap: () => _openCategorySheet(
                              context,
                              existing: categories,
                              editing: categories[i],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: KcSpacing.md),
                FilledButton.icon(
                  onPressed: () =>
                      _openCategorySheet(context, existing: categories),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Kategori'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

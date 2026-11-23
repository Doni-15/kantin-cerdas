import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/owner/application/owner_menu_controller.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_categories_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_menu_form_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_menu_list_row.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';
import 'package:kantin_cerdas/widgets/kc_search_field.dart';

class OwnerMenusPage extends ConsumerStatefulWidget {
  const OwnerMenusPage({
    super.key,
    required this.accountId,
    required this.onOpenStallTab,
  });

  final String accountId;
  final VoidCallback onOpenStallTab;

  @override
  ConsumerState<OwnerMenusPage> createState() => _OwnerMenusPageState();
}

class _OwnerMenusPageState extends ConsumerState<OwnerMenusPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!_tabs.indexIsChanging && mounted) setState(() {});
    });
  final _search = TextEditingController();
  Timer? _debounce;
  var _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final next = _search.text.trim();
      if (next != _query) setState(() => _query = next);
    });
  }

  Future<void> _openForm([OwnerMenuItem? item]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OwnerMenuFormPage(accountId: widget.accountId, existing: item),
      ),
    );
  }

  Future<void> _toggleAvailability(OwnerMenuItem item) async {
    try {
      await ref
          .read(ownerMenuControllerProvider)
          .setAvailability(
            accountId: widget.accountId,
            menuId: item.id,
            isAvailable: !item.isAvailable,
          );
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(error, fallback: 'Gagal mengubah ketersediaan menu.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stallAsync = ref.watch(ownerStallProvider(widget.accountId));
    final showingArchived = _tabs.index == 1;
    final hasStall = stallAsync.asData?.value.stall != null;
    final menusQuery = (
      accountId: widget.accountId,
      archived: showingArchived,
      query: _query,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Menu Aktif'),
            Tab(text: 'Arsip'),
          ],
        ),
      ),
      floatingActionButton: (hasStall && !showingArchived)
          ? Semantics(
              label: 'Tambah menu',
              button: true,
              child: FloatingActionButton(
                tooltip: 'Tambah menu',
                onPressed: () => _openForm(),
                child: const Icon(Icons.add),
              ),
            )
          : null,
      body: SafeArea(
        child: stallAsync.when(
          loading: () => const OwnerLoadingView(message: 'Memuat data menu…'),
          error: (error, _) => OwnerErrorView(
            error: error,
            onRetry: () => ref.invalidate(ownerStallProvider(widget.accountId)),
          ),
          data: (bundle) {
            if (bundle.stall == null) {
              return OwnerEmptyView(
                icon: Icons.restaurant_menu_outlined,
                title: 'Buat profil kantin dahulu',
                description:
                    'Menu dan kategori disiapkan setelah profil kantin dibuat.',
                action: FilledButton(
                  onPressed: widget.onOpenStallTab,
                  child: const Text('Buat Kantin'),
                ),
              );
            }

            final menusAsync = ref.watch(ownerMenusProvider(menusQuery));
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KcSpacing.md,
                    KcSpacing.md,
                    KcSpacing.md,
                    KcSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      KcSearchField(
                        controller: _search,
                        labelText: 'Cari menu',
                        maxLength: 100,
                        hideCounter: true,
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: KcSpacing.xs),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const Icon(Icons.category_outlined),
                          title: const Text('Kategori Menu'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => OwnerCategoriesPage(
                                accountId: widget.accountId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: menusAsync.when(
                    loading: () =>
                        const OwnerLoadingView(message: 'Memuat daftar menu…'),
                    error: (error, _) => OwnerErrorView(
                      error: error,
                      onRetry: () =>
                          ref.invalidate(ownerMenusProvider(menusQuery)),
                    ),
                    data: (menus) {
                      if (menus.isEmpty) {
                        return OwnerEmptyView(
                          icon: showingArchived
                              ? Icons.archive_outlined
                              : Icons.fastfood_outlined,
                          title: showingArchived
                              ? 'Belum ada menu diarsipkan'
                              : _query.isNotEmpty
                              ? 'Menu tidak ditemukan'
                              : 'Belum ada menu',
                          description: showingArchived
                              ? 'Menu yang diarsipkan akan tampil di sini dan dapat dipulihkan.'
                              : _query.isEmpty
                              ? 'Tekan tombol + untuk menambah menu pertama kantinmu.'
                              : null,
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.refresh(ownerMenusProvider(menusQuery).future),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            KcSpacing.md,
                            KcSpacing.xs,
                            KcSpacing.md,
                            88,
                          ),
                          children: [
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (var i = 0; i < menus.length; i++) ...[
                                    if (i > 0) const Divider(height: 1),
                                    OwnerMenuListRow(
                                      accountId: widget.accountId,
                                      item: menus[i],
                                      onTap: () => _openForm(menus[i]),
                                      onToggleAvailability: menus[i].isArchived
                                          ? null
                                          : () => _toggleAvailability(menus[i]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

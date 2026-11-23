import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/catalog/application/catalog_providers.dart';
import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_menu_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_stall_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_search_result_cards.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_search_field.dart';

class CustomerGlobalSearchPage extends ConsumerStatefulWidget {
  const CustomerGlobalSearchPage({
    super.key,
    required this.session,
    required this.onOrderCompleted,
  });

  final AuthSession session;
  final ValueChanged<String> onOrderCompleted;

  @override
  ConsumerState<CustomerGlobalSearchPage> createState() =>
      _CustomerGlobalSearchPageState();
}

class _CustomerGlobalSearchPageState
    extends ConsumerState<CustomerGlobalSearchPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  var _generation = 0;
  var _query = '';
  var _loading = false;
  Object? _error;
  List<CatalogStall> _stalls = const [];
  List<CatalogMenuItem> _menus = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _runSearch);
  }

  Future<void> _runSearch() async {
    _debounce?.cancel();
    final trimmed = _searchCtrl.text.trim();
    if (trimmed.isEmpty) {
      _generation++;
      setState(() {
        _query = '';
        _loading = false;
        _error = null;
        _stalls = const [];
        _menus = const [];
      });
      return;
    }

    final gen = ++_generation;
    setState(() {
      _query = trimmed;
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final currentSession =
          ref.read(authControllerProvider).asData?.value ?? widget.session;
      final results = await Future.wait([
        repo.list(currentSession, CatalogKind.stalls, query: trimmed),
        repo.list(currentSession, CatalogKind.menu, query: trimmed),
      ]);
      if (!mounted || gen != _generation) return;
      setState(() {
        _stalls = results[0].items.whereType<CatalogStall>().toList(
          growable: false,
        );
        _menus = results[1].items.whereType<CatalogMenuItem>().toList(
          growable: false,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _pushResultPage(Widget page) {
    _searchFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page)).whenComplete(() {
      if (mounted) _searchFocus.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cari')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KcSpacing.md,
                KcSpacing.xs,
                KcSpacing.md,
                KcSpacing.sm,
              ),
              child: KcSearchField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                maxLength: 100,
                hideCounter: true,
                hintText: 'Cari kantin atau makanan...',
                onChanged: _onChanged,
                onSubmitted: (_) => _runSearch(),
                showClearButton: _searchCtrl.text.isNotEmpty,
                onClear: () {
                  _searchCtrl.clear();
                  _runSearch();
                },
              ),
            ),
            Expanded(
              child: switch ((_query.isEmpty, _loading, _error)) {
                (true, _, _) => const CustomerEmptyView(
                  icon: Icons.search,
                  title: 'Mau cari apa?',
                  subtitle:
                      'Ketik nama kantin atau nama makanan untuk mencari di seluruh kantin terbit.',
                ),
                (false, true, _) => const Center(
                  child: CircularProgressIndicator(),
                ),
                (false, false, final Object err) => CustomerErrorView(
                  error: err,
                  fallback: 'Pencarian gagal. Periksa koneksi Anda.',
                  onRetry: _runSearch,
                ),
                _ when _stalls.isEmpty && _menus.isEmpty =>
                  const CustomerEmptyView(
                    icon: Icons.search_off,
                    title: 'Tidak ada hasil',
                    subtitle:
                        'Coba kata kunci nama kantin atau menu yang lain.',
                  ),
                _ => ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    KcSpacing.md,
                    KcSpacing.xs,
                    KcSpacing.md,
                    KcSpacing.lg * 2,
                  ),
                  children: [
                    if (_stalls.isNotEmpty) ...[
                      Text('Kantin', style: theme.textTheme.titleMedium),
                      const SizedBox(height: KcSpacing.xs),
                      for (final stall in _stalls)
                        CustomerSearchStallCard(
                          stall: stall,
                          onTap: () => _pushResultPage(
                            CustomerStallDetailPage(
                              accountId: widget.session.account.id,
                              stallId: stall.id,
                              initialStallName: stall.name,
                              onOrderCompleted: widget.onOrderCompleted,
                            ),
                          ),
                        ),
                      const SizedBox(height: KcSpacing.sm),
                    ],
                    if (_menus.isNotEmpty) ...[
                      Text('Menu', style: theme.textTheme.titleMedium),
                      const SizedBox(height: KcSpacing.xs),
                      for (final menu in _menus)
                        CustomerSearchMenuCard(
                          menu: menu,
                          onTap: () => _pushResultPage(
                            CustomerMenuDetailPage(
                              accountId: widget.session.account.id,
                              menuId: menu.id,
                              initialMenuName: menu.name,
                              onOrderCompleted: widget.onOrderCompleted,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

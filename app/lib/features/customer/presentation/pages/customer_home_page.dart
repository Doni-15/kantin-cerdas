import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/catalog/application/catalog_providers.dart';
import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_stall_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_cart_action_button.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_home_widgets.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

enum _StallOpenFilter {
  all('Semua'),
  open('Buka'),
  closed('Tutup');

  const _StallOpenFilter(this.label);
  final String label;
}

class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({
    super.key,
    required this.session,
    required this.initialPage,
    required this.onOpenSearchTab,
    required this.onOrderCompleted,
  });

  final AuthSession session;
  final FutureOr<CatalogPage> initialPage;
  final VoidCallback onOpenSearchTab;
  final ValueChanged<String> onOrderCompleted;

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  final _stalls = <String, CustomerStallSummary>{};
  String? _nextCursor;
  Object? _error;
  String? _failedCursor;
  var _loading = true;
  var _generation = 0;
  var _filter = _StallOpenFilter.all;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPage;
    if (initial is CatalogPage) {
      _applyPage(initial, cursor: null);
    } else {
      unawaited(_fetch(null, initialFuture: initial));
    }
  }

  Future<void> _fetch(
    String? cursor, {
    FutureOr<CatalogPage>? initialFuture,
  }) async {
    final generation = ++_generation;
    try {
      final repo = ref.read(catalogRepositoryProvider);
      final currentSession =
          ref.read(authControllerProvider).asData?.value ?? widget.session;
      final page =
          await (initialFuture ??
              repo.list(currentSession, CatalogKind.stalls, cursor: cursor));
      if (!mounted || generation != _generation) return;
      setState(() => _applyPage(page, cursor: cursor));
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _failedCursor = cursor;
        _loading = false;
      });
    }
  }

  void _applyPage(CatalogPage page, {required String? cursor}) {
    if (cursor == null) _stalls.clear();
    for (final item in page.items) {
      if (item is CatalogStall) {
        _stalls[item.id] = CustomerStallSummary.fromCatalogStall(item);
      }
    }
    _nextCursor = page.nextCursor;
    _error = null;
    _loading = false;
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch(null);
  }

  void _openStall(CustomerStallSummary stall) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerStallDetailPage(
          accountId: widget.session.account.id,
          stallId: stall.id,
          initialStallName: stall.name,
          onOrderCompleted: widget.onOrderCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allStalls = _stalls.values.toList(growable: false);
    final visible = switch (_filter) {
      _StallOpenFilter.all => allStalls,
      _StallOpenFilter.open =>
        allStalls.where((s) => s.isOpen).toList(growable: false),
      _StallOpenFilter.closed =>
        allStalls.where((s) => !s.isOpen).toList(growable: false),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mau makan apa hari ini?'),
        actions: [
          CustomerCartAppBarButton(
            accountId: widget.session.account.id,
            onOpenedCartOrder: widget.onOrderCompleted,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  KcSpacing.md,
                  KcSpacing.xs,
                  KcSpacing.md,
                  KcSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomerHomeSearchPrompt(onTap: widget.onOpenSearchTab),
                      const SizedBox(height: KcSpacing.md),
                      Text(
                        'Jelajahi Kantin',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: KcSpacing.xs),
                      Wrap(
                        spacing: KcSpacing.xs,
                        runSpacing: KcSpacing.xs,
                        children: [
                          for (final option in _StallOpenFilter.values)
                            ChoiceChip(
                              label: Text(option.label),
                              selected: _filter == option,
                              onSelected: (_) {
                                if (_filter != option) {
                                  setState(() => _filter = option);
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading && allStalls.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.all(KcSpacing.md),
                  sliver: SliverToBoxAdapter(child: CustomerHomeSkeletonList()),
                )
              else if (_error != null && allStalls.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: CustomerErrorView(
                    error: _error,
                    fallback: 'Katalog kantin tidak dapat dimuat.',
                    onRetry: _refresh,
                  ),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: CustomerEmptyView(
                    icon: Icons.storefront_outlined,
                    title: 'Belum ada kantin',
                    subtitle: _filter == _StallOpenFilter.all
                        ? 'Belum ada kantin yang diterbitkan saat ini.'
                        : 'Tidak ada kantin berstatus ${_filter.label}.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: KcSpacing.md),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KcSpacing.xs),
                    itemBuilder: (context, index) {
                      final stall = visible[index];
                      return CustomerStallCard(
                        stall: stall,
                        onTap: () => _openStall(stall),
                      );
                    },
                  ),
                ),
              if (allStalls.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    KcSpacing.md,
                    KcSpacing.sm,
                    KcSpacing.md,
                    KcSpacing.lg * 3,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: switch ((_loading, _error, _nextCursor)) {
                      (true, _, _) => const LinearProgressIndicator(
                        semanticsLabel: 'Memuat kantin berikutnya',
                      ),
                      (false, final Object err, _) => Padding(
                        padding: const EdgeInsets.only(top: KcSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                presentAppError(
                                  err,
                                  fallback: 'Gagal memuat kantin berikutnya.',
                                ),
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _loading = true);
                                _fetch(_failedCursor);
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                      (false, null, final String cursor) => Center(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _loading = true);
                            _fetch(cursor);
                          },
                          child: const Text('Muat lagi'),
                        ),
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

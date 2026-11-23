import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_stall_detail_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_stall_row.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_search_field.dart';

class AdminStallsPage extends ConsumerStatefulWidget {
  const AdminStallsPage({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<AdminStallsPage> createState() => _AdminStallsPageState();
}

class _AdminStallsPageState extends ConsumerState<AdminStallsPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  var _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = (accountId: widget.accountId, query: _query);
    final stallsAsync = ref.watch(adminStallsProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Kantin')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KcSpacing.md,
                KcSpacing.xs,
                KcSpacing.md,
                KcSpacing.xs,
              ),
              child: KcSearchField(
                controller: _searchCtrl,
                hintText: 'Cari kantin atau pemilik...',
                onChanged: _onSearchChanged,
                showClearButton: _searchCtrl.text.isNotEmpty,
                clearTooltip: 'Hapus pencarian',
                clearIcon: Icons.close,
                onClear: () {
                  _searchCtrl.clear();
                  _debounce?.cancel();
                  setState(() => _query = '');
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: stallsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AdminErrorView(
                  error: error,
                  fallback: 'Daftar kantin tidak dapat dimuat.',
                  onRetry: () => ref.invalidate(adminStallsProvider(filter)),
                ),
                data: (stalls) {
                  if (stalls.isEmpty) {
                    return const AdminEmptyView(
                      icon: Icons.storefront_outlined,
                      title: 'Kantin tidak ditemukan',
                      subtitle:
                          'Belum ada kantin yang sesuai dengan pencarian.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(adminStallsProvider(filter));
                      await ref.read(adminStallsProvider(filter).future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: KcSpacing.xs,
                      ),
                      itemCount: stalls.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final stall = stalls[index];
                        return AdminStallRow(
                          accountId: widget.accountId,
                          stall: stall,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminStallDetailPage(
                                accountId: widget.accountId,
                                stallId: stall.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

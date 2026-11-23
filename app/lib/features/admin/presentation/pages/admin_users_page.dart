import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_user_detail_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_state_views.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_user_row.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_search_field.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _statusFilter;
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
    final filter = (
      accountId: widget.accountId,
      role: null,
      status: _statusFilter,
      query: _query,
    );
    final usersAsync = ref.watch(adminUsersProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Pengguna')),
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
                hintText: 'Cari nama atau email...',
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: KcSpacing.md,
                vertical: 4,
              ),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: KcSpacing.xs),
                  ChoiceChip(
                    label: const Text('Aktif'),
                    selected: _statusFilter == 'active',
                    onSelected: (_) => setState(() => _statusFilter = 'active'),
                  ),
                  const SizedBox(width: KcSpacing.xs),
                  ChoiceChip(
                    label: const Text('Nonaktif'),
                    selected: _statusFilter == 'inactive',
                    onSelected: (_) =>
                        setState(() => _statusFilter = 'inactive'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AdminErrorView(
                  error: error,
                  fallback: 'Daftar pengguna tidak dapat dimuat.',
                  onRetry: () => ref.invalidate(adminUsersProvider(filter)),
                ),
                data: (users) {
                  if (users.isEmpty) {
                    return const AdminEmptyView(
                      icon: Icons.people_outline,
                      title: 'Pengguna tidak ditemukan',
                      subtitle: 'Ubah kata kunci atau filter status akun.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(adminUsersProvider(filter));
                      await ref.read(adminUsersProvider(filter).future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: KcSpacing.xs,
                      ),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return AdminUserRow(
                          user: user,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminUserDetailPage(
                                accountId: widget.accountId,
                                userId: user.id,
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

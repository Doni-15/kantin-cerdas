import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_load_error.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_page_body.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_user_list.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_user_search_form.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _search = '';
  final List<String?> _cursors = [null];

  AdminUserQuery get _query => (search: _search, cursor: _cursors.last);

  void _searchUsers(String search) {
    if (search == _search && _cursors.length == 1) {
      ref.invalidate(adminUsersProvider(_query));
      return;
    }
    setState(() {
      _search = search;
      _cursors
        ..clear()
        ..add(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUsersProvider(_query);
    final state = ref.watch(provider);
    return AdminPageBody(
      title: 'Pengguna',
      description: 'Cari akun dan lihat peran serta status aksesnya.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminUserSearchForm(onSearch: _searchUsers),
          const SizedBox(height: KcSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref.invalidate(provider),
              icon: const Icon(Icons.refresh),
              label: const Text('Muat ulang'),
            ),
          ),
          const SizedBox(height: KcSpacing.sm),
          if (_search.isNotEmpty) ...[
            Text('Hasil pencarian: $_search'),
            const SizedBox(height: KcSpacing.sm),
          ],
          state.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const KcLoadingSkeleton(
              label: 'Memuat pengguna',
              layout: KcSkeletonLayout.list,
            ),
            error: (error, _) => AdminLoadError(
              error: error,
              onRetry: () => ref.invalidate(provider),
            ),
            data: (page) => AdminUserList(
              page: page,
              pageNumber: _cursors.length,
              hasSearch: _search.isNotEmpty,
              onPrevious: _cursors.length == 1
                  ? null
                  : () {
                      setState(() => _cursors.removeLast());
                    },
              onNext:
                  page.nextCursor == null || _cursors.contains(page.nextCursor)
                  ? null
                  : () {
                      setState(() => _cursors.add(page.nextCursor));
                    },
            ),
          ),
          if (state.hasError && _cursors.length > 1)
            TextButton(
              onPressed: () {
                setState(() => _cursors.removeLast());
              },
              child: const Text('Kembali ke halaman sebelumnya'),
            ),
        ],
      ),
    );
  }
}

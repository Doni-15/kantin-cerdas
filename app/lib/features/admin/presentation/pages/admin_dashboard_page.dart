import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_load_error.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_page_body.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_summary_grid.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminSummaryProvider);
    return AdminPageBody(
      title: 'Dashboard admin',
      description: 'Ringkasan pengguna, stan, pengajuan, dan pesanan kantin.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: KcSpacing.xs,
            runSpacing: KcSpacing.xs,
            children: [
              FilledButton.icon(
                onPressed: () => context.go(Routes.adminUsers),
                icon: const Icon(Icons.people_outline),
                label: const Text('Lihat pengguna'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(Routes.adminApplications),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Tinjau pengajuan'),
              ),
              TextButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => ref.invalidate(adminSummaryProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Muat ulang'),
              ),
            ],
          ),
          const SizedBox(height: KcSpacing.md),
          state.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const KcLoadingSkeleton(
              label: 'Memuat ringkasan',
              layout: KcSkeletonLayout.summary,
            ),
            error: (error, _) => AdminLoadError(
              error: error,
              onRetry: () => ref.invalidate(adminSummaryProvider),
            ),
            data: (summary) => AdminSummaryGrid(summary: summary),
          ),
        ],
      ),
    );
  }
}

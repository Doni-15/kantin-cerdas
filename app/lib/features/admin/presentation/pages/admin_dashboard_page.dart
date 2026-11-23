import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_application_detail_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_state_views.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_summary_grid.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({
    super.key,
    required this.session,
    required this.onOpenAccount,
    required this.onOpenApplicationsTab,
    required this.onOpenUsersTab,
    required this.onOpenStallsTab,
  });

  final AuthSession session;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenApplicationsTab;
  final VoidCallback onOpenUsersTab;
  final VoidCallback onOpenStallsTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = session.account.id;
    final dashboardAsync = ref.watch(adminDashboardProvider(accountId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            tooltip: 'Akun Admin',
            onPressed: onOpenAccount,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AdminErrorView(
            error: error,
            fallback: 'Ringkasan administratif tidak dapat dimuat.',
            onRetry: () => ref.invalidate(adminDashboardProvider(accountId)),
          ),
          data: (summary) {
            final recent = summary.recentPendingApplications.take(2).toList();
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminDashboardProvider(accountId));
                await ref.read(adminDashboardProvider(accountId).future);
              },
              child: ListView(
                padding: const EdgeInsets.all(KcSpacing.md),
                children: [
                  Text(
                    'Ringkasan Administratif',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: KcSpacing.xs),
                  AdminCompactSummaryGrid(
                    summary: summary,
                    onTapUsers: onOpenUsersTab,
                    onTapApplications: onOpenApplicationsTab,
                    onTapStalls: onOpenStallsTab,
                  ),
                  const SizedBox(height: KcSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pengajuan Menunggu Review (${summary.pendingApplications})',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: onOpenApplicationsTab,
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: KcSpacing.xs),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: KcSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 36,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: KcSpacing.xs),
                          Text(
                            'Belum ada pengajuan Owner yang menunggu.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const Divider(height: 1),
                    for (final item in recent) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        title: Text(item.applicantName),
                        subtitle: Text(
                          '${item.plannedStallName} · ${item.plannedLocation}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdminApplicationDetailPage(
                              accountId: accountId,
                              applicationId: item.id,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

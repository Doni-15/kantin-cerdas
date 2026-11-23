import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_application_detail_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_formatters.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_state_views.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_status_pills.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminApplicationsPage extends ConsumerStatefulWidget {
  const AdminApplicationsPage({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<AdminApplicationsPage> createState() =>
      _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends ConsumerState<AdminApplicationsPage> {
  var _scope = 'pending';

  @override
  Widget build(BuildContext context) {
    final query = (accountId: widget.accountId, scope: _scope);
    final appsAsync = ref.watch(adminApplicationsProvider(query));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan')),
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
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Menunggu')),
                      selected: _scope == 'pending',
                      onSelected: (_) => setState(() => _scope = 'pending'),
                    ),
                  ),
                  const SizedBox(width: KcSpacing.xs),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Riwayat')),
                      selected: _scope == 'history',
                      onSelected: (_) => setState(() => _scope = 'history'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: appsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AdminErrorView(
                  error: error,
                  fallback: 'Daftar pengajuan tidak dapat dimuat.',
                  onRetry: () =>
                      ref.invalidate(adminApplicationsProvider(query)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return AdminEmptyView(
                      icon: Icons.assignment_outlined,
                      title: _scope == 'pending'
                          ? 'Belum ada pengajuan menunggu'
                          : 'Belum ada riwayat pengajuan',
                      subtitle: _scope == 'pending'
                          ? 'Pengajuan Customer baru akan tampil di sini.'
                          : 'Keputusan Disetujui atau Ditolak akan tampil di sini.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(adminApplicationsProvider(query));
                      await ref.read(adminApplicationsProvider(query).future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: KcSpacing.xs,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final app = items[index];
                        return ListTile(
                          title: Text(app.applicantName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${app.plannedStallName} · ${app.plannedLocation}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatAdminDate(app.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildApplicationStatusPill(context, app.status),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminApplicationDetailPage(
                                accountId: widget.accountId,
                                applicationId: app.id,
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

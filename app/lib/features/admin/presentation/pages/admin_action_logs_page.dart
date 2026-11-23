import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_formatters.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminActionLogsPage extends ConsumerWidget {
  const AdminActionLogsPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (accountId: accountId, targetUserId: null);
    final logsAsync = ref.watch(adminActionLogsProvider(key));

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Audit Admin')),
      body: SafeArea(
        child: logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AdminErrorView(
            error: error,
            fallback: 'Riwayat audit tidak dapat dimuat.',
            onRetry: () => ref.invalidate(adminActionLogsProvider(key)),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return const AdminEmptyView(
                icon: Icons.history_outlined,
                title: 'Belum ada riwayat tindakan',
                subtitle:
                    'Semua keputusan review dan status akun akan tercatat di sini.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: KcSpacing.xs),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(log.actionType.label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target: ${log.targetUserName ?? log.targetUserId}'),
                      Text(
                        'Admin: ${log.adminName} · ${formatAdminDate(log.createdAt)}',
                      ),
                      if (log.reason != null) Text('Alasan: ${log.reason}'),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

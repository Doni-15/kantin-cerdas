import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_recovery_banner.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_mutation_controller.dart';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_user_access_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_user_detail_provider.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_load_error.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/users/admin_user_details.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/users/admin_user_access_actions.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/users/admin_user_access_notice.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminUserDetailPage extends ConsumerWidget {
  const AdminUserDetailPage({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminUserDetailProvider(userId);
    final attempt = ref.watch(adminUserAccessControllerProvider)[userId];
    final state = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail pengguna'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.adminUsers);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(KcSpacing.lg),
              children: [
                const AdminRecoveryBanner(),
                if (attempt != null &&
                    (attempt.blocked ||
                        attempt.error != null ||
                        attempt.savedIsActive != null ||
                        attempt.reconciled)) ...[
                  AdminUserAccessNotice(
                    state: attempt,
                    onRefresh: ref.watch(adminMutationProvider).busy
                        ? null
                        : () => ref
                              .read(adminMutationControllerProvider.notifier)
                              .recover(),
                  ),
                  const SizedBox(height: KcSpacing.md),
                ],
                if (state.error is! AdminNotConfiguredFailure)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: state.isLoading || (attempt?.busy ?? false)
                          ? null
                          : () => ref.invalidate(provider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Muat ulang'),
                    ),
                  ),
                state.when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () => const KcLoadingSkeleton(
                    label: 'Memuat pengguna',
                    layout: KcSkeletonLayout.detail,
                  ),
                  error: (error, _) => AdminLoadError(
                    error: error,
                    onRetry: () => ref.invalidate(provider),
                  ),
                  data: (record) => record == null
                      ? const KcStatusPanel(
                          title: 'Pengguna tidak ditemukan',
                          message:
                              'Akun ini tidak tersedia untuk sesi admin saat ini.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AdminUserDetails(record: record),
                            const SizedBox(height: KcSpacing.md),
                            AdminUserAccessActions(
                              key: ValueKey(
                                '${record.user.id}:${record.version}',
                              ),
                              record: record,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

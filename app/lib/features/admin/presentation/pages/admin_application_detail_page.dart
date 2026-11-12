import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_recovery_banner.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_mutation_controller.dart';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_application_review_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_application_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_load_error.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/applications/admin_application_details.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/applications/admin_application_review_actions.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/applications/admin_application_review_notice.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminApplicationDetailPage extends ConsumerWidget {
  const AdminApplicationDetailPage({super.key, required this.applicationId});
  final String applicationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminApplicationDetailProvider(applicationId);
    final attempt = ref.watch(
      adminApplicationReviewControllerProvider,
    )[applicationId];
    final state = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail pengajuan'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.adminApplications);
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
                    (attempt.busy ||
                        attempt.blocked ||
                        attempt.error != null ||
                        attempt.saved ||
                        attempt.reconciled)) ...[
                  AdminApplicationReviewNotice(
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
                    label: 'Memuat pengajuan',
                    layout: KcSkeletonLayout.detail,
                  ),
                  error: (error, _) => AdminLoadError(
                    error: error,
                    onRetry: () => ref.invalidate(provider),
                  ),
                  data: (application) => application == null
                      ? const KcStatusPanel(
                          title: 'Pengajuan tidak ditemukan',
                          message:
                              'Pengajuan ini tidak tersedia untuk sesi admin saat ini.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AdminApplicationDetails(application: application),
                            const SizedBox(height: KcSpacing.md),
                            AdminApplicationReviewActions(
                              key: ValueKey(
                                '${application.id}:${application.version}',
                              ),
                              application: application,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/session_restore_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_order_detail_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_mutation_notice.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/orders/owner_order_detail_content.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/orders/owner_order_detail_error.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderDetailPage extends ConsumerWidget {
  const OwnerOrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    if (auth.isLoading ||
        auth.hasError ||
        user == null ||
        !user.isActive ||
        user.role != UserRole.owner) {
      return const SessionRestorePage();
    }
    final provider = ownerOrderDetailProvider(orderId);
    final detail = ref.watch(provider);
    final mutation = ref.watch(ownerMutationProvider);
    final error = detail.asError?.error;
    final unavailable = error is OwnerNotConfiguredFailure;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail pesanan stan'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const BackButtonIcon(),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.ownerOrders);
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
              padding: const EdgeInsets.all(KcSpacing.md),
              children: [
                OwnerMutationNotice(
                  operationPrefix: 'order:$orderId',
                  exactOperation: true,
                ),
                const SizedBox(height: KcSpacing.sm),
                if (!unavailable)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: detail.isLoading || mutation.busy
                          ? null
                          : () => ref.invalidate(provider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Muat ulang'),
                    ),
                  ),
                detail.when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () => const KcLoadingSkeleton(
                    label: 'Memuat detail pesanan stan',
                    layout: KcSkeletonLayout.detail,
                  ),
                  error: (error, _) => OwnerOrderDetailError(
                    error: error,
                    onRetry: () => ref.invalidate(provider),
                  ),
                  data: (order) => order == null
                      ? const KcStatusPanel(
                          title: 'Pesanan tidak ditemukan',
                          message:
                              'Pesanan dengan referensi ini tidak tersedia untuk stanmu.',
                          icon: Icons.search_off,
                        )
                      : OwnerOrderDetailContent(order: order),
                ),
                const SizedBox(height: KcSpacing.lg),
                OutlinedButton(
                  onPressed: () => context.go(Routes.ownerOrders),
                  child: const Text('Lihat daftar pesanan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

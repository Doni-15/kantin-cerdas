import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_cancellation_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_cancellation_recovery_panel.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/session_restore_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_detail_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_order_detail_content.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_order_detail_error.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerOrderDetailPage extends ConsumerWidget {
  const CustomerOrderDetailPage({
    super.key,
    required this.orderId,
    this.showSubmissionNotice = false,
  });
  final String orderId;
  final bool showSubmissionNotice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    if (auth.isLoading ||
        auth.hasError ||
        user == null ||
        !user.isActive ||
        !user.role.canUseCustomerFeatures) {
      return const SessionRestorePage();
    }
    final provider = customerOrderDetailProvider(orderId);
    final cancellation = ref.watch(customerOrderCancellationProvider);
    final hasCancellationNotice =
        cancellation.hasNotice &&
        (cancellation.request == null ||
            cancellation.request!.orderId == orderId);
    final detail = ref.watch(provider);
    final error = detail.asError?.error;
    final unavailable = error is CustomerFeatureNotConfiguredFailure;
    final submission = ref.watch(customerOrderControllerProvider);
    final latestOrder = detail.asData?.value;
    final confirmedNow =
        showSubmissionNotice &&
        orderId.trim().isNotEmpty &&
        !hasCancellationNotice &&
        (latestOrder == null || !latestOrder.status.isTerminal) &&
        !submission.isLoading &&
        !submission.hasError &&
        submission.asData?.value == orderId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail pesanan'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const BackButtonIcon(),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.customerOrders);
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
                if (confirmedNow) ...[
                  const KcStatusPanel(
                    title: 'Pesanan berhasil dibuat',
                    message:
                        'Pembuatan sudah dikonfirmasi. Status terbaru dan pembayaran diperiksa secara terpisah.',
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: KcSpacing.md),
                ],
                CustomerCancellationRecoveryPanel(orderId: orderId),
                const SizedBox(height: KcSpacing.md),
                if (!unavailable)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: detail.isLoading || cancellation.busy
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
                    label: 'Memuat detail pesanan',
                    layout: KcSkeletonLayout.detail,
                  ),
                  error: (error, _) => CustomerOrderDetailError(
                    error: error,
                    onRetry: () => ref.invalidate(provider),
                  ),
                  data: (order) => order == null
                      ? const KcStatusPanel(
                          title: 'Pesanan tidak ditemukan',
                          message:
                              'Pesanan dengan referensi ini tidak ditemukan untuk akunmu.',
                          icon: Icons.search_off,
                        )
                      : CustomerOrderDetailContent(order: order),
                ),
                const SizedBox(height: KcSpacing.lg),
                KcButton(
                  label: 'Lihat pesanan aktif',
                  onPressed: () => context.go(Routes.customerOrders),
                ),
                const SizedBox(height: KcSpacing.sm),
                KcButton(
                  label: 'Lihat riwayat',
                  variant: KcButtonVariant.outlined,
                  onPressed: () => context.go(Routes.customerHistory),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

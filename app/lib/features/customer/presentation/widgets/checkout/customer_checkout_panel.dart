import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_order_failure_message.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/customer_checkout_submit.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Pemulihan tetap tersedia walaupun keranjang kosong setelah restart.
class CustomerCheckoutPanel extends ConsumerWidget {
  const CustomerCheckoutPanel({super.key, this.allowSubmission = false});
  final bool allowSubmission;
  Future<void> _recover(
    BuildContext context,
    WidgetRef ref,
    String customerId,
  ) async {
    final session = ref.read(authStateProvider.notifier);
    final generation = session.sessionGeneration;
    final orderId = await ref
        .read(customerOrderControllerProvider.notifier)
        .recover();
    if (!context.mounted ||
        !identical(ref.read(authStateProvider.notifier), session) ||
        session.sessionGeneration != generation) {
      return;
    }
    final auth = ref.read(authStateProvider);
    final user = auth.isLoading ? null : auth.asData?.value;
    if (user?.id != customerId ||
        user?.isActive != true ||
        user?.role.canUseCustomerFeatures != true) {
      return;
    }
    // Halaman induk memiliki listener navigasi yang tetap hidup saat panel diganti.
    if (orderId != null) {
      return;
    }
    final persisted = ref.read(customerCheckoutJournalProvider(customerId));
    final result = ref.read(customerOrderControllerProvider);
    if (!persisted.isLoading &&
        !persisted.hasError &&
        persisted.asData != null &&
        persisted.asData!.value == null &&
        !result.isLoading &&
        !result.hasError) {
      KcSnackBar.info(
        context,
        'Pengiriman ini tidak menghasilkan pesanan. Keranjang bisa ditinjau kembali.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.isLoading ? null : auth.asData?.value;
    if (user == null || !user.isActive || !user.role.canUseCustomerFeatures) {
      return const SizedBox.shrink();
    }
    final persisted = ref.watch(customerCheckoutJournalProvider(user.id));
    final submission = ref.watch(customerOrderControllerProvider);
    if (persisted.isLoading) {
      return const KcStatusPanel(
        title: 'Menyiapkan status pesanan',
        message:
            'Keranjang ditahan sementara status pengiriman dibaca atau disimpan.',
        loading: true,
      );
    }
    if (persisted.hasError || persisted.asData == null) {
      return KcStatusPanel(
        title: 'Status pengiriman belum dapat dibaca',
        message:
            'Keranjang dikunci agar pesanan yang mungkin sudah terkirim tidak dikirim lagi. Coba baca ulang status lokal.',
        icon: Icons.lock_outline,
        action: KcButton(
          label: 'Baca ulang status lokal',
          onPressed: submission.isLoading
              ? null
              : () {
                  ref
                      .read(customerCheckoutJournalProvider(user.id).notifier)
                      .reload();
                },
        ),
      );
    }
    final pending = persisted.asData!.value;
    final error = submission.isLoading ? null : submission.asError?.error;
    if (pending != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KcStatusPanel(
            title: submission.isLoading
                ? 'Memproses pesanan'
                : 'Hasil pesanan belum dipastikan',
            message:
                'Keranjang dikunci sampai hasil pengiriman ini dipastikan. Pemeriksaan hanya membaca hasil, tanpa membuat pesanan baru.',
            loading: submission.isLoading,
            icon: Icons.pending_actions,
            action: KcButton(
              label: 'Periksa hasil pesanan',
              isLoading: submission.isLoading,
              onPressed: submission.isLoading
                  ? null
                  : () => _recover(context, ref, user.id),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: KcSpacing.sm),
            KcStatusPanel(
              title: 'Pemeriksaan belum selesai',
              message: customerOrderFailureMessage(error),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          KcStatusPanel(
            title: 'Informasi pemesanan',
            message: customerOrderFailureMessage(error),
          ),
          const SizedBox(height: KcSpacing.sm),
        ],
        if (allowSubmission) const CustomerCheckoutSubmit(),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_application_review_state.dart';

class AdminApplicationReviewNotice extends StatelessWidget {
  const AdminApplicationReviewNotice({
    super.key,
    required this.state,
    required this.onRefresh,
  });
  final AdminApplicationReviewState state;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) {
    if (state.busy) {
      return const KcStatusPanel(
        title: 'Mengirim keputusan',
        message: 'Tunggu hingga hasil pengiriman tersedia.',
        loading: true,
      );
    }
    if (state.unresolvedVersion != null) {
      return KcStatusPanel(
        title: 'Hasil keputusan belum pasti',
        message:
            'Keputusan mungkin sudah diterapkan. Periksa hasil pengiriman dengan ID yang tersimpan sebelum mengambil keputusan lagi.',
        action: TextButton(
          onPressed: onRefresh,
          child: const Text('Periksa hasil'),
        ),
      );
    }
    if (state.saved) {
      return const KcStatusPanel(
        title: 'Keputusan tersimpan',
        message:
            'Layanan telah mengonfirmasi keputusan. Detail akan dimuat ulang.',
      );
    }
    if (state.reconciled) {
      return const KcStatusPanel(
        title: 'Pengiriman tidak diterapkan',
        message:
            'Layanan memastikan request sebelumnya tidak diterapkan. Tinjau rincian terbaru sebelum melanjutkan.',
      );
    }
    final message = switch (state.error) {
      AdminMutationStorageFailure() =>
        'Penyimpanan penanda belum dapat dipastikan. Gunakan pemulihan perubahan.',
      AdminMutationPreSendFailure() =>
        'Request belum dikirim. Tinjau data, lalu coba lagi.',
      AdminNotConfiguredFailure() =>
        'Layanan peninjauan belum tersedia. Keputusan belum dikirim.',
      AdminAccessFailure() =>
        'Sesi admin tidak memiliki akses. Masuk kembali dengan akun admin aktif.',
      AdminReviewConflictFailure() =>
        'Pengajuan sudah berubah. Muat dan tinjau kembali data terbaru.',
      AdminReviewRejectedFailure() =>
        'Layanan menolak keputusan. Periksa data sebelum mencoba lagi.',
      _ => 'Keputusan belum dapat dikirim.',
    };
    return KcStatusPanel(title: 'Keputusan belum tersimpan', message: message);
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_user_access_state.dart';

class AdminUserAccessNotice extends StatelessWidget {
  const AdminUserAccessNotice({
    super.key,
    required this.state,
    required this.onRefresh,
  });
  final AdminUserAccessState state;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) {
    if (state.busy) {
      return const KcStatusPanel(
        title: 'Mengirim perubahan akses',
        message: 'Tunggu hingga hasil pengiriman tersedia.',
        loading: true,
      );
    }
    if (state.unresolvedVersion != null) {
      return KcStatusPanel(
        title: 'Hasil perubahan belum pasti',
        message:
            'Perubahan mungkin sudah diterapkan. Periksa hasil pengiriman dengan ID yang tersimpan sebelum mengirim perubahan lagi.',
        action: TextButton(
          onPressed: onRefresh,
          child: const Text('Periksa hasil'),
        ),
      );
    }
    if (state.savedIsActive != null) {
      return KcStatusPanel(
        title: 'Perubahan akses dikonfirmasi',
        message: state.savedIsActive!
            ? 'Layanan mengonfirmasi aktivasi akun. Status terbaru akan dimuat ulang.'
            : 'Layanan mengonfirmasi penonaktifan akun. Status terbaru akan dimuat ulang.',
      );
    }
    if (state.reconciled) {
      return const KcStatusPanel(
        title: 'Pengiriman tidak diterapkan',
        message:
            'Layanan memastikan request sebelumnya tidak diterapkan. Tinjau status terbaru sebelum melanjutkan.',
      );
    }
    final message = switch (state.error) {
      AdminMutationStorageFailure() =>
        'Penyimpanan penanda belum dapat dipastikan. Gunakan pemulihan perubahan.',
      AdminMutationPreSendFailure() =>
        'Request belum dikirim. Tinjau data, lalu coba lagi.',
      AdminNotConfiguredFailure() =>
        'Layanan pengelolaan akses belum tersedia. Perubahan belum dikirim.',
      AdminAccessFailure() =>
        'Sesi tidak memiliki akses. Masuk kembali dengan akun admin aktif.',
      AdminUserAccessConflictFailure() =>
        'Data pengguna sudah berubah. Muat dan tinjau kembali status terbaru.',
      AdminUserAccessRejectedFailure() =>
        'Perubahan ditolak. Periksa akun tujuan dan alasan sebelum mencoba lagi.',
      _ => 'Perubahan akses belum dapat dikirim.',
    };
    return KcStatusPanel(title: 'Perubahan belum tersimpan', message: message);
  }
}

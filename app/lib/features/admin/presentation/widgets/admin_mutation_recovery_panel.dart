import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_mutation_controller.dart';

class AdminMutationRecoveryPanel extends ConsumerWidget {
  const AdminMutationRecoveryPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminMutationProvider);
    if (state.journalLoading) {
      return const KcStatusPanel(
        title: 'Memeriksa penanda perubahan',
        message: 'Pengiriman ditahan selama penyimpanan lokal diproses.',
        loading: true,
      );
    }
    if (state.journalError != null) {
      return KcStatusPanel(
        title: 'Penyimpanan belum dapat diakses',
        message:
            'Baca ulang penanda sebelum melakukan perubahan. Penanda tidak dihapus secara paksa.',
        action: KcButton(
          label: 'Baca ulang penanda',
          isLoading: state.busy,
          onPressed: state.busy
              ? null
              : () => ref
                    .read(adminMutationControllerProvider.notifier)
                    .reloadJournal(),
        ),
      );
    }
    if (state.unresolved) {
      final message = switch (state.error) {
        AdminNotConfiguredFailure() =>
          'Layanan pemeriksaan hasil belum tersedia. Penanda tetap disimpan.',
        AdminAccessFailure() =>
          'Akses pemeriksaan ditolak. Periksa sesi admin; penanda tetap disimpan.',
        _ =>
          'Hasil perubahan belum dipastikan. Pemeriksaan memakai ID yang sama tanpa mengirim ulang perubahan.',
      };
      return KcStatusPanel(
        title: 'Periksa hasil perubahan admin',
        message: message,
        action: KcButton(
          label: 'Periksa hasil',
          isLoading: state.busy,
          onPressed: state.busy
              ? null
              : () => ref
                    .read(adminMutationControllerProvider.notifier)
                    .recover(),
        ),
      );
    }
    return KcStatusPanel(
      title: state.succeeded
          ? 'Perubahan sudah diterapkan'
          : 'Penanda sudah diperiksa',
      message: state.reconciled
          ? 'Request sebelumnya dipastikan tidak diterapkan. Tinjau data terbaru sebelum mengambil tindakan lagi.'
          : 'Tinjau data terbaru sebelum mengambil tindakan selanjutnya.',
    );
  }
}

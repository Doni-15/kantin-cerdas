import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/mappers/owner_labels.dart';

class OwnerMutationRecoveryPanel extends ConsumerWidget {
  const OwnerMutationRecoveryPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerMutationProvider);
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
            'Penanda perubahan belum dapat dipastikan. Pembacaan ulang tidak menghapus penanda atau mengirim perubahan.',
        action: KcButton(
          label: 'Baca ulang penanda',
          isLoading: state.busy,
          onPressed: state.busy
              ? null
              : () => ref
                    .read(ownerMutationControllerProvider.notifier)
                    .reloadJournal(),
        ),
      );
    }
    if (state.uncertain) {
      return KcStatusPanel(
        title: 'Periksa hasil perubahan',
        message: state.error != null
            ? ownerFailureMessage(state.error!)
            : 'Ada perubahan yang belum selesai diperiksa. Penandanya tetap tersimpan setelah keluar akun atau menutup aplikasi.',
        action: KcButton(
          label: 'Periksa hasil',
          isLoading: state.busy,
          onPressed: state.busy
              ? null
              : () => ref
                    .read(ownerMutationControllerProvider.notifier)
                    .recover(),
        ),
      );
    }
    return KcStatusPanel(
      title: state.succeeded
          ? 'Perubahan sudah diterapkan'
          : 'Penanda sudah diperiksa',
      message: state.error != null
          ? ownerFailureMessage(state.error!)
          : 'Tinjau data terbaru. Jika form menu masih terbuka, tutup dan buka kembali sebelum membuat perubahan baru.',
    );
  }
}

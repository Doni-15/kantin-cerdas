import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/food_preferences_save_state.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/food_preferences_message.dart';

class FoodPreferencesNotice extends StatelessWidget {
  const FoodPreferencesNotice({
    super.key,
    required this.state,
    required this.onRecover,
    required this.onReloadJournal,
  });
  final FoodPreferencesSaveState state;
  final VoidCallback? onRecover;
  final VoidCallback? onReloadJournal;
  @override
  Widget build(BuildContext context) {
    if (state.busy) {
      return const KcStatusPanel(
        title: 'Memproses preferensi',
        message: 'Menunggu penyimpanan atau pemeriksaan hasil selesai.',
        loading: true,
      );
    }
    if (state.journalLoading) {
      return const KcStatusPanel(
        title: 'Memeriksa penyimpanan sebelumnya',
        message: 'Membaca penanda pada perangkat ini.',
        loading: true,
      );
    }
    if (state.journalError != null) {
      return KcStatusPanel(
        title: 'Penyimpanan sementara ditahan',
        message:
            'Penanda pada perangkat belum dapat dibaca. Baca ulang setelah penyimpanan perangkat tersedia.',
        action: TextButton(
          onPressed: onReloadJournal,
          child: const Text('Baca ulang penanda'),
        ),
      );
    }
    if (state.pending != null) {
      return KcStatusPanel(
        title: 'Periksa hasil penyimpanan sebelumnya',
        message: state.error == null
            ? 'Hasil penyimpanan belum dikonfirmasi. Periksa hasil sebelum mengubah preferensi lagi.'
            : foodPreferencesMessage(state.error),
        action: TextButton(
          onPressed: onRecover,
          child: const Text('Periksa hasil'),
        ),
      );
    }
    if (state.saved) {
      return const KcStatusPanel(
        title: 'Preferensi tersimpan',
        message:
            'Penyimpanan telah dikonfirmasi. Data terbaru dimuat kembali dari layanan.',
      );
    }
    if (state.reconciled) {
      return const KcStatusPanel(
        title: 'Penyimpanan sebelumnya tidak diterapkan',
        message:
            'Layanan memastikan permintaan sebelumnya tidak akan diterapkan. Tinjau data terbaru sebelum menyimpan lagi.',
      );
    }
    if (!state.configured) {
      return const KcStatusPanel(
        title: 'Layanan preferensi belum tersedia',
        message: 'Penyimpanan akan tersedia setelah layanan dihubungkan.',
      );
    }
    return KcStatusPanel(
      title: state.needsRefresh
          ? 'Muat preferensi terbaru'
          : 'Preferensi belum tersimpan',
      message: state.needsRefresh && state.error == null
          ? 'Penanda sudah diperiksa. Muat data terbaru sebelum menyimpan kembali.'
          : foodPreferencesMessage(state.error),
    );
  }
}

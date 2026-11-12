import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/canteen_application_submit_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/canteen_application_message.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_journal_provider.dart';

/// Selalu di luar cabang pembacaan server agar recovery tetap bisa diakses.
class CanteenApplicationNotice extends ConsumerWidget {
  const CanteenApplicationNotice({
    super.key,
    required this.customerId,
    required this.onRefresh,
  });
  final String customerId;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(canteenApplicationJournalProvider(customerId));
    final submit = ref.watch(canteenApplicationSubmitProvider);
    if (journal.isLoading) {
      return const KcStatusPanel(
        title: 'Menyiapkan pengajuan',
        message: 'Memeriksa dan menyimpan penanda pengiriman di perangkat.',
        action: LinearProgressIndicator(
          semanticsLabel: 'Memproses penanda pengajuan',
        ),
      );
    }
    if (journal.hasError || journal.asData == null) {
      return KcStatusPanel(
        title: 'Penyimpanan belum dapat diakses',
        message:
            'Pengiriman ditahan agar pengajuan tidak terduplikasi. Coba baca kembali penanda pengiriman.',
        action: TextButton(
          onPressed: submit.busy
              ? null
              : () => ref
                    .read(
                      canteenApplicationJournalProvider(customerId).notifier,
                    )
                    .reload(),
          child: const Text('Baca ulang penanda'),
        ),
      );
    }
    if (journal.asData!.value != null) {
      return KcStatusPanel(
        title: submit.busy ? 'Memproses pengajuan' : 'Periksa hasil pengiriman',
        message: submit.error != null
            ? canteenApplicationMessage(submit.error!)
            : 'Ada pengiriman yang belum selesai diperiksa. Penandanya tetap tersimpan setelah keluar dari akun atau menutup aplikasi.',
        action: KcButton(
          label: 'Periksa hasil',
          isLoading: submit.busy,
          onPressed: submit.busy
              ? null
              : () => ref
                    .read(canteenApplicationSubmitProvider.notifier)
                    .recover(),
        ),
      );
    }
    if (submit.needsRefresh) {
      return KcStatusPanel(
        title: 'Tinjau data terbaru',
        message: submit.error != null
            ? canteenApplicationMessage(submit.error!)
            : 'Pengiriman sebelumnya dipastikan tidak diterapkan. Muat status terbaru sebelum membuat pengajuan baru.',
        action: KcButton(
          label: 'Muat data terbaru',
          isLoading: submit.busy,
          onPressed: submit.busy ? null : onRefresh,
        ),
      );
    }
    if (submit.error != null) {
      return KcStatusPanel(
        title: 'Pengajuan belum selesai',
        message: canteenApplicationMessage(submit.error!),
      );
    }
    if (submit.succeeded) {
      return const KcStatusPanel(
        title: 'Pengajuan diterima',
        message:
            'Pengajuan berhasil dikirim untuk ditinjau. Status terbaru ditampilkan di bawah.',
      );
    }
    return const SizedBox.shrink();
  }
}

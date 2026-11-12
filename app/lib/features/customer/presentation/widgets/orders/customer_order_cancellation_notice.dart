import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_cancellation_state.dart';

class CustomerOrderCancellationNotice extends StatelessWidget {
  const CustomerOrderCancellationNotice({
    super.key,
    required this.state,
    required this.onRecover,
    required this.onReloadJournal,
  });
  final CustomerOrderCancellationState state;
  final VoidCallback? onRecover;
  final VoidCallback? onReloadJournal;
  @override
  Widget build(BuildContext context) {
    final request = state.request;
    final subject = request == null
        ? 'Pembatalan'
        : 'Pembatalan pesanan ${request.orderNumber}';
    if (state.busy) {
      return KcStatusPanel(
        title: subject,
        message: 'Menunggu pengiriman atau pemeriksaan hasil selesai.',
        loading: true,
      );
    }
    if (state.journalLoading) {
      return const KcStatusPanel(
        title: 'Memeriksa pembatalan sebelumnya',
        message: 'Membaca penanda pada perangkat ini.',
        loading: true,
      );
    }
    if (state.journalError != null) {
      return KcStatusPanel(
        title: 'Pembatalan sementara ditahan',
        message:
            'Penanda pada perangkat belum dapat dibaca atau diperbarui. Baca ulang setelah penyimpanan tersedia.',
        action: TextButton(
          onPressed: onReloadJournal,
          child: const Text('Baca ulang penanda'),
        ),
      );
    }
    if (state.unresolved) {
      final unavailable =
          state.error is CustomerOrderCancellationNotConfiguredFailure;
      final forbidden =
          state.error is CustomerOrderCancellationForbiddenFailure;
      return KcStatusPanel(
        title: '$subject belum terkonfirmasi',
        message: unavailable
            ? 'Layanan pemeriksaan hasil belum tersedia. Penanda tetap disimpan.'
            : forbidden
            ? 'Akses pemeriksaan hasil belum tersedia. Periksa sesi akunmu; penanda tetap disimpan.'
            : 'Periksa hasil permintaan sebelumnya sebelum membatalkan pesanan lagi. Pemeriksaan tidak mengirim ulang pembatalan.',
        action: TextButton(
          onPressed: onRecover,
          child: const Text('Periksa hasil'),
        ),
      );
    }
    if (state.confirmed) {
      return KcStatusPanel(
        title: '$subject dikonfirmasi',
        message:
            'Layanan mengonfirmasi pesanan dibatalkan dan tidak ditagihkan. Detail dan daftar dimuat ulang.',
      );
    }
    if (state.reconciled) {
      return KcStatusPanel(
        title: '$subject tidak diterapkan',
        message:
            'Layanan memastikan permintaan ini tidak akan diterapkan. Tinjau status terbaru sebelum bertindak lagi.',
      );
    }
    final message = switch (state.error) {
      CustomerOrderCancellationNotConfiguredFailure() =>
        'Layanan pembatalan belum tersedia. Permintaan belum dikirim.',
      CustomerOrderCancellationForbiddenFailure() =>
        'Akses pesanan tidak tersedia. Periksa kembali sesi akunmu.',
      CustomerOrderCancellationConflictFailure() =>
        'Pesanan sudah berubah atau tidak dapat dibatalkan. Muat ulang status terbaru.',
      CustomerOrderCancellationRejectedFailure() =>
        'Layanan menolak pembatalan. Periksa status pesanan atau hubungi stan.',
      CustomerOrderCancellationStorageFailure() =>
        'Penanda pembatalan belum dapat diperbarui. Periksa penyimpanan perangkat.',
      CustomerOrderCancellationPreSendFailure() =>
        'Pembatalan belum dikirim. Tinjau pesanan lalu coba lagi.',
      _ => 'Permintaan pembatalan belum dapat diproses.',
    };
    return KcStatusPanel(title: '$subject belum berhasil', message: message);
  }
}

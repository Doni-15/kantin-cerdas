import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_feature_message.dart';

String canteenApplicationMessage(Object error) {
  if (error is! CanteenApplicationFailure) {
    return customerFeatureMessage(error);
  }
  return switch (error) {
    CanteenApplicationNotConfiguredFailure() =>
      'Layanan pengajuan belum tersedia saat ini.',
    CanteenApplicationForbiddenFailure() =>
      'Akses tidak tersedia. Periksa kembali sesi akunmu.',
    CanteenApplicationRejectedFailure() =>
      'Pengajuan belum diterima. Periksa kembali isianmu.',
    CanteenApplicationConflictFailure() =>
      'Status pengajuan telah berubah. Muat data terbaru sebelum mengirim kembali.',
    CanteenApplicationPreSendFailure() =>
      'Pengajuan belum dikirim. Periksa isian, lalu coba lagi.',
    CanteenApplicationUnconfirmedFailure() =>
      'Hasil pengiriman belum pasti. Periksa hasil; jangan mengirim ulang.',
    CanteenApplicationStorageFailure() =>
      'Penanda pengajuan belum dapat dibaca atau disimpan. Pengiriman ditahan.',
  };
}

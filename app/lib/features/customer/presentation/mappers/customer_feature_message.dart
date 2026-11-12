import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';

String customerFeatureMessage(Object error) {
  if (error is CustomerFeatureFailure) {
    return switch (error) {
      CustomerFeatureNotConfiguredFailure() =>
        'Layanan ini belum tersedia saat ini.',
      CustomerFeatureForbiddenFailure() =>
        'Akses tidak tersedia. Periksa kembali sesi akunmu.',
      CustomerFeatureRejectedFailure() =>
        'Pengajuan belum dapat diterima. Periksa kembali isianmu.',
      CustomerFeatureUnconfirmedFailure() =>
        'Hasil pengiriman belum terkonfirmasi. Periksa status sebelum mengirim ulang.',
      CustomerFeatureReadTimeoutFailure() =>
        'Waktu memuat data habis. Coba muat ulang.',
      CustomerFeatureInvalidDataFailure() =>
        'Data dari layanan belum sesuai. Coba muat ulang atau hubungi pengelola.',
    };
  }
  return 'Data belum dapat diproses. Silakan coba lagi nanti.';
}

import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';

String customerCatalogErrorTitle(Object error) {
  if (error is CustomerCatalogFailure) {
    return switch (error) {
      CustomerCatalogNotConfiguredFailure() =>
        'Layanan katalog belum terhubung',
      CustomerCatalogNetworkFailure() => 'Koneksi katalog terputus',
      CustomerCatalogServerFailure() => 'Layanan katalog sedang bermasalah',
      CustomerCatalogUnexpectedFailure() => 'Katalog belum dapat dimuat',
    };
  }
  return 'Katalog belum dapat dimuat';
}

String customerCatalogErrorMessage(Object error) {
  if (error is CustomerCatalogFailure) {
    return switch (error) {
      CustomerCatalogNotConfiguredFailure() =>
        'Sumber data katalog belum dikonfigurasi pada aplikasi ini.',
      CustomerCatalogNetworkFailure() =>
        'Periksa koneksi internet Anda lalu coba muat ulang.',
      CustomerCatalogServerFailure() =>
        'Server sedang mengalami kendala. Coba lagi beberapa saat lagi.',
      CustomerCatalogUnexpectedFailure() =>
        'Data katalog tidak sesuai atau belum dapat diproses. Coba muat ulang.',
    };
  }
  return 'Coba muat ulang beberapa saat lagi.';
}

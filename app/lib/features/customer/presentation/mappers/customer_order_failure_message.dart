import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';

const _unconfirmedOrderMessage =
    'Hasil pemesanan belum terkonfirmasi. '
    'Pengiriman ulang ditahan sampai hasilnya dipastikan.';

/// Pesan untuk error submit dari CustomerOrderController.
///
/// Tidak menampilkan exception.toString(), respons mentah backend,
/// maupun detail teknis kepada pengguna.
///
/// Error yang belum dikenali tidak dianggap sebagai penolakan pasti
/// dan tidak diberi anjuran untuk langsung mengirim ulang pesanan.
String customerOrderFailureMessage(Object error) {
  if (error is! CustomerOrderFailure) {
    return _unconfirmedOrderMessage;
  }

  return switch (error) {
    CustomerOrderNotConfiguredFailure() =>
      'Layanan pemesanan belum terhubung. Hasil pesanan belum dapat diperiksa.',
    CustomerOrderPreSendFailure() =>
      'Pengiriman belum dimulai. Periksa koneksi sebelum mencoba lagi.',
    CustomerOrderLocalStorageFailure() =>
      'Status pengiriman lokal belum dapat dipastikan. Keranjang ditahan sampai status berhasil dibaca kembali.',
    CustomerOrderCatalogChangedFailure() =>
      'Pilihan atau katalog berubah. Tinjau kembali harga, menu, dan status stan sebelum mengirim pesanan.',
    CustomerOrderPriceChangedFailure() =>
      'Harga berubah dan pesanan belum dibuat. Muat ulang katalog lalu tinjau total sebelum mencoba lagi.',
    CustomerOrderForbiddenFailure() =>
      'Akses pemesanan tidak tersedia. Periksa kembali sesi akunmu.',
    CustomerOrderRejectedFailure() =>
      'Pesanan ditolak. Tinjau kembali pilihanmu sebelum mencoba lagi.',
    CustomerOrderUnconfirmedFailure() => _unconfirmedOrderMessage,
    CustomerOrderUnexpectedFailure() => _unconfirmedOrderMessage,
  };
}

// TODO(backend): Perinci pesan penolakan setelah alasan terstruktur tersedia
// pada kontrak domain dan API. Jangan menebak alasan dari status HTTP
// atau langsung menampilkan teks respons backend.

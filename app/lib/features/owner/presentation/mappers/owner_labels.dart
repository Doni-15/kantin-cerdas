import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';

String ownerCategoryLabel(OwnerMenuCategory category) => category.label;

String ownerOrderLabel(OrderStatus status) => switch (status) {
  OrderStatus.waiting => 'Baru',
  OrderStatus.processing => 'Diproses',
  OrderStatus.ready => 'Siap diambil',
  OrderStatus.completed => 'Selesai',
  OrderStatus.rejected => 'Ditolak',
  OrderStatus.cancelled => 'Dibatalkan',
};

String ownerFailureMessage(Object error) {
  if (error is OwnerFailure) {
    return switch (error) {
      OwnerStorageFailure() =>
        'Penanda perubahan belum dapat dibaca atau disimpan. Pengiriman ditahan.',
      OwnerNotConfiguredFailure() =>
        'Layanan pengelolaan stan belum tersedia saat ini.',
      OwnerForbiddenFailure() => 'Akses tidak tersedia. Periksa sesi akunmu.',
      OwnerNoStallFailure() => 'Belum ada stan yang terhubung dengan akunmu.',
      OwnerConflictFailure() =>
        'Data sudah berubah. Muat ulang dan tinjau data terbaru sebelum mencoba lagi.',
      OwnerRejectedFailure() =>
        'Perubahan belum dapat diterima. Periksa kembali isianmu.',
      OwnerUnconfirmedFailure() =>
        'Hasil perubahan belum terkonfirmasi. Pengiriman ulang ditahan sampai hasilnya dipastikan.',
      OwnerInvalidDataFailure() =>
        'Data dari layanan belum sesuai. Coba muat ulang halaman.',
      OwnerReadTimeoutFailure() =>
        'Waktu pembacaan data stan habis. Periksa koneksi lalu coba lagi.',
      OwnerPreSendFailure() =>
        'Permintaan belum dikirim. Periksa kembali isian lalu coba lagi.',
    };
  }
  return 'Data belum dapat dimuat. Periksa koneksi lalu coba lagi.';
}

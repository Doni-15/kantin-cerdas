import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

String orderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.waiting => 'Menunggu konfirmasi',
  OrderStatus.processing => 'Sedang disiapkan',
  OrderStatus.ready => 'Siap diambil',
  OrderStatus.completed => 'Selesai',
  OrderStatus.rejected => 'Ditolak',
  OrderStatus.cancelled => 'Dibatalkan',
};

String orderPaymentLabel(OrderPaymentStatus status) => switch (status) {
  OrderPaymentStatus.unpaid => 'Belum dibayar',
  OrderPaymentStatus.paid => 'Sudah dibayar',
  OrderPaymentStatus.notCharged => 'Tidak ditagihkan',
};

String orderNextStep(OrderStatus status) => switch (status) {
  OrderStatus.waiting =>
    'Pesanan menunggu konfirmasi stan. Muat ulang untuk melihat perubahan status.',
  OrderStatus.processing =>
    'Stan sedang menyiapkan pesananmu. Tunggu sampai statusnya siap diambil.',
  OrderStatus.ready =>
    'Datangi stan dan tunjukkan nomor pesanan saat mengambil makanan. Periksa status pembayaran di bawah.',
  OrderStatus.completed =>
    'Pesanan telah diselesaikan oleh stan. Detailnya tetap tersedia di riwayat.',
  OrderStatus.rejected =>
    'Stan menolak pesanan ini. Periksa alasan yang tercantum pada rincian pesanan.',
  OrderStatus.cancelled =>
    'Pesanan ini telah dibatalkan. Kamu dapat memilih menu kembali dari beranda.',
};

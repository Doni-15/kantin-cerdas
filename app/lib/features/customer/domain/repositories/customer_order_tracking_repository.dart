import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

/// Pemantauan dan pembatalan terpisah dari CustomerOrderRepository untuk checkout.
abstract interface class CustomerOrderTrackingRepository {
  /// True hanya jika adapter mendukung CAS, dedupe, dan lookup receipt pembatalan.
  bool get isCancellationConfigured;

  /// Lookup tidak mengirim ulang pembatalan. Receipt terikat pada customer+ID
  /// request, order, stan, nomor pesanan dan expectedVersion yang sama.
  /// applied berarti commit cancelled+notCharged. notApplied hanya jika ID
  /// disegel terhadap late commit; ID tak ditemukan tanpa seal tetap pending.
  /// Receipt immutable dan retensi/segel ID harus disepakati sebelum integrasi.
  Future<OrderCancellationLookup> lookupCancellation({
    required String mutationId,
  });

  /// Server menentukan customer dari sesi aktif, memeriksa ownership,
  /// waiting+unpaid, dan expectedVersion dalam transaksi yang sama.
  /// Pembatalan dan penerimaan oleh owner bersaing pada versi yang sama:
  /// hanya satu boleh commit. Semua perubahan menaikkan versi secara monoton.
  /// Hasil sukses harus cancelled+notCharged. Tidak ada refund/pembayaran
  /// atau perubahan cart dari client. Status terminal tidak boleh dibuka kembali.
  /// Replay versi lama tidak boleh mengubah data, termasuk setelah restart.
  /// Gunakan CustomerOrderCancellationFailure; penolakan definitif harus
  /// menjamin tidak ada commit oleh request ini, selain itu unknown.
  /// Tidak ada retry mutasi otomatis. Catatan audit dibuat di server.
  /// mutationId diikat ke payload asli dan dideduplikasi secara atomik.
  /// Respons mempertahankan identitas, rincian, total, catatan dan waktu pembuatan.
  Future<OrderRecord> cancelMyOrder(
    CustomerOrderCancellation cancellation, {
    required String mutationId,
  });

  /// Pembacaan otoritatif menggunakan identitas akun dari sesi server.
  /// Cache yang belum diverifikasi tidak boleh dipakai untuk rekonsiliasi mutasi.
  /// Null hanya setelah server memastikan pesanan tidak ditemukan untuk sesi.
  /// Gangguan jaringan, akses ditolak, dan layanan belum terhubung harus melempar.
  /// Adapter memeriksa otorisasi, enum, harga snapshot, dan waktu dari server.
  /// Operasi ini tidak membuat pesanan atau mengubah status pembayaran.
  Future<OrderRecord?> getMyOrder({required String orderId});

  /// Server menentukan pemilik dari sesi; history berisi status terminal.
  Future<OrderRecordPage> listMyOrders({
    required bool history,
    String? cursor,
    int limit = 30,
  });
}

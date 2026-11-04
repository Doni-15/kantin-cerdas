import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';

/// Batas akses sumber data untuk pembuatan pesanan.
///
/// Draft merupakan input internal aplikasi, bukan representasi payload JSON.
/// Implementasi bertanggung jawab memetakannya sesuai kontrak API.
abstract interface class CustomerOrderDataSource {
  /// True hanya jika adapter memenuhi kontrak harga, pembayaran tunai,
  /// otorisasi, deduplikasi submissionId, dan lookup hasil pengiriman.
  /// Nilai ini tidak menggantikan pemeriksaan otorisasi/koneksi pada layanan.
  bool get isCheckoutConfigured;

  /// Mengirim pilihan pengguna dan mengembalikan ID pesanan dari backend.
  ///
  /// Future hanya boleh berhasil jika backend mengonfirmasi pesanan dibuat
  /// dan respons berisi ID pesanan yang valid serta tidak kosong.
  ///
  /// Kegagalan tidak boleh diganti dengan ID lokal atau nilai kosong.
  /// Hasil yang belum diketahui juga tidak boleh dianggap sebagai penolakan
  /// yang memastikan pesanan belum dibuat.
  ///
  /// confirmation adalah batas persetujuan harga, bukan harga tepercaya.
  /// Secara atomik: periksa sesi, stan buka, menu tersedia, unit price setiap
  /// menu, kuantitas/catatan, total persis, dan tunai saat pengambilan.
  /// Harga berbeda => CustomerOrderPriceChangedFailure tanpa membuat pesanan.
  /// Jangan menambah biaya/mengganti harga. Sukses awal: waiting + unpaid.
  /// submissionId milik sesi harus idempoten; lookup memulihkan ID yang sama.
  /// Repository/sumber data tidak mengubah keranjang atau melakukan navigasi.
  Future<String> createOrder({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  });

  /// Server memverifikasi sesi dan kepemilikan. Lookup tidak membuat pesanan.
  /// notCreated hanya sah jika key disegel terhadap request terlambat.
  Future<OrderSubmissionLookup> lookupSubmission({
    required String submissionId,
  });
}

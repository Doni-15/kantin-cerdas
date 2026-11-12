import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';

/// Kontrak pemesanan untuk pelanggan yang sudah terautentikasi.
///
/// Implementasi berada di lapisan data. Domain tidak mengetahui endpoint,
/// format JSON, client HTTP, maupun penyimpanan token.
abstract interface class CustomerOrderRepository {
  /// True hanya jika adapter memenuhi kontrak harga, pembayaran tunai,
  /// otorisasi, deduplikasi submissionId, dan lookup hasil pengiriman.
  /// Nilai ini tidak menggantikan pemeriksaan otorisasi/koneksi pada layanan.
  bool get isCheckoutConfigured;

  /// Membuat pesanan berdasarkan snapshot pilihan pengguna.
  ///
  /// Mengembalikan ID pesanan yang tidak kosong hanya setelah backend
  /// mengonfirmasi pesanan berhasil dibuat.
  ///
  /// Backend tetap menjadi sumber validasi menu, stan, ketersediaan,
  /// harga, dan ketentuan pembayaran.
  ///
  /// Kegagalan atau hasil yang belum terkonfirmasi harus diteruskan sebagai
  /// error, bukan diubah menjadi ID lokal atau keberhasilan buatan.
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

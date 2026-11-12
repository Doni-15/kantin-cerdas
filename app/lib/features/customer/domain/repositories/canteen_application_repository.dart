import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';

abstract interface class CanteenApplicationRepository {
  /// Kemampuan adapter, bukan indikator koneksi atau pengganti otorisasi server.
  bool get isSubmissionConfigured;

  /// Null hanya berarti pembacaan berhasil dan belum ada pengajuan.
  Future<CanteenApplication?> getMyApplication();

  /// Backend memeriksa akun aktif dari sesi, bukan mempercayai customerId.
  /// Atomik: cocokkan latest previousId/version (null hanya jika belum pernah
  /// ada), status rejected untuk pengajuan ulang, dan tidak ada pengajuan aktif.
  /// Buat record baru submitted tanpa reason; simpan riwayat lama tanpa perubahan.
  /// Tetapkan ID/waktu/versi di server; jangan mengubah role pada submit.
  /// Deduplikasi per akun+submissionId dengan payload identik. Return receipt
  /// awal immutable; jangan mengganti isi atau mengembalikan snapshot review.
  /// Timeout/response invalid adalah unconfirmed. Kegagalan definitif harus
  /// menjamin tidak ada commit sekarang maupun dari request terlambat.
  Future<CanteenApplication> submit(PendingCanteenApplication submission);

  /// Hanya memeriksa ID tersimpan; tidak membuat pengajuan atau mengirim submit.
  /// Receipt submitted harus snapshot awal immutable untuk ID tersebut.
  /// notSubmitted hanya sah setelah ID ditutup atomik terhadap late commit.
  /// Tidak ditemukan/belum terlihat bukan notSubmitted: kembalikan pending.
  /// Retensi receipt/tombstone tidak boleh menghidupkan kembali request lama.
  Future<CanteenApplicationLookup> lookupSubmission({
    required String submissionId,
  });
}

import 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_page.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_summary.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_page.dart';

/// Kontrak layanan admin. Adapter backend wajib memeriksa otorisasi admin.
abstract interface class AdminRepository {
  /// Aktif hanya jika kedua mutasi dan lookup receipt didukung adapter.
  bool get isMutationConfigured;

  /// Receipt terikat ke admin+mutationId dan payload asli, termasuk alasan.
  /// applied memuat versi hasil dan intent yang benar. Approval hanya applied
  /// jika keputusan, satu stan, dan pemberian role owner telah commit atomik.
  /// notApplied hanya setelah ID disegel terhadap late commit. Tidak ditemukan
  /// atau versi data lebih baru saja bukan hasil request: kembalikan pending.
  Future<AdminMutationLookup> lookupMutation({required String mutationId});

  /// Semua penulisan wajib dedupe admin+mutationId dengan payload identik,
  /// CAS/otorisasi atomik, receipt immutable, serta retensi seal/receipt.
  /// Error definitif menjamin tidak ada commit maupun late commit ID yang sama.

  /// Baca otoritatif berdasarkan ID dengan sesi admin aktif. Null hanya jika
  /// server memastikan akun tidak ditemukan; jaringan/akses gagal harus melempar.
  Future<AdminUserRecord?> getUser({required String userId});

  /// Server wajib menolak target diri sendiri/admin lain dan perubahan role.
  /// expectedVersion dibandingkan atomik; setiap perubahan profil/akses/role
  /// meningkatkan versi. Jangan menerima replay versi lama, termasuk setelah restart.
  /// Perubahan akses dan audit alasan harus konsisten. Akun nonaktif wajib ditolak
  /// pada semua operasi layanan, termasuk dengan token sesi yang sudah terbit.
  /// Aktif kembali tidak otomatis memulihkan sesi yang telah dicabut.
  /// Hanya penolakan tanpa commit boleh dianggap definitif. Timeout atau response
  /// invalid setelah kirim adalah unknown; client tidak mengirim ulang otomatis.
  Future<AdminUserRecord> setUserAccess(
    AdminUserAccessChange change, {
    required String mutationId,
  });

  /// Server wajib memeriksa sesi admin. Cursor terikat filter dan urutan stabil.
  Future<AdminApplicationPage> listApplications({
    CanteenApplicationStatus? status,
    String? cursor,
    int limit = 30,
  });

  /// Pembacaan otoritatif. Null hanya jika server memastikan tidak ditemukan.
  /// Error akses/jaringan tidak boleh disamarkan sebagai null.
  Future<CanteenApplication?> getApplication({required String applicationId});

  /// Server: admin aktif, submitted/reviewing saja, expectedVersion atomik,
  /// versi selalu bertambah. Approval membuat tepat satu stan, menautkan akun,
  /// dan memberikan akses owner secara konsisten/idempoten. Client tidak menulis role.
  /// Replay versi lama tidak boleh memberi efek samping, termasuk setelah restart.
  /// Error definitif hanya jika tidak ada commit; timeout/response invalid = unknown.
  Future<CanteenApplication> reviewApplication(
    AdminApplicationReview review, {
    required String mutationId,
  });

  Future<AdminSummary> getSummary();

  /// Pencarian nama/email oleh server. Cursor terikat pada pencarian dan urutan.
  /// Hasil kosong hanya dikembalikan setelah pembacaan berhasil.
  Future<AdminUserPage> listUsers({
    required String search,
    String? cursor,
    int limit = 30,
  });
}

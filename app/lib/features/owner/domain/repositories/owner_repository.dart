import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

/// Backend wajib memeriksa pemilik, versi, dan transisi secara atomik.
/// Akun tidak boleh memilih ownerId sendiri atau membuat stan tanpa persetujuan.
abstract interface class OwnerRepository {
  /// True hanya jika semua mutasi dan lookup receipt di bawah didukung adapter.
  bool get isMutationConfigured;

  /// Lookup berdasarkan akun sesi + mutationId, tidak mengirim ulang mutasi.
  /// Backend menyimpan receipt immutable yang terikat ke payload asli, jenis,
  /// stan, target, expectedVersion dan intent status. Receipt applied menyertakan
  /// ID/versi hasil (delete memakai tombstone). Data terkini bukan receipt.
  /// notApplied mensyaratkan ID disegel atomik terhadap request terlambat.
  /// Tidak ditemukan, timeout, atau perubahan versi saja berarti pending.
  Future<OwnerMutationLookup> lookupMutation({required String mutationId});

  /// Semua metode tulis: deduplikasi per akun+mutationId; payload berbeda dengan
  /// ID sama ditolak. Server memastikan kepemilikan dan CAS secara atomik.
  /// Failure definitif menjamin tidak ada commit/late commit; lainnya unconfirmed.
  /// Jangan aktifkan adapter tanpa retensi dedupe/receipt/tombstone yang memadai.

  Future<OwnerStall?> getMyStall();
  Future<OwnerMenuPage> listMenus({
    required String stallId,
    required String search,
    bool? available,
    String? cursor,
    int limit = 30,
  });

  /// Buat: ID baru dan versi >= 1. Edit: CAS expectedVersion dan versi meningkat.
  /// Seluruh field hasil wajib sama dengan input yang dinormalisasi.
  /// Konflik/penolakan definitif tidak boleh melakukan penulisan parsial.
  Future<OwnerMenu> saveMenu(
    OwnerMenuInput input, {
    required String mutationId,
  });

  /// Hanya selesai normal setelah penghapusan terkonfirmasi dengan CAS.
  /// Timeout/koneksi putus setelah pengiriman adalah unconfirmed, bukan sukses.
  /// Rincian pesanan lama tetap utuh; otorisasi memakai sesi aktif.
  Future<void> deleteMenu({
    required String id,
    required int expectedVersion,
    required String mutationId,
  });

  /// CAS expectedVersion; versi meningkat dan identitas pemilik tetap.
  /// Hasil harus mencerminkan seluruh isian; jangan mengembalikan snapshot lama.
  Future<OwnerStall> saveStall(
    OwnerStallInput input, {
    required String mutationId,
  });
  Future<OrderRecordPage> listOrders({
    required String stallId,
    OrderStatus? status,
    String? cursor,
    int limit = 30,
  });

  /// Membaca satu pesanan hanya dari stan milik sesi owner aktif.
  /// Null berarti tidak ditemukan; gangguan layanan harus melempar failure.
  Future<OrderRecord?> getMyOrder({
    required String stallId,
    required String orderId,
  });

  /// CAS atomik pada expectedVersion. Sukses mengembalikan versi lebih baru;
  /// rejected => notCharged, completed => paid, processing/ready => unpaid.
  /// Harga dan rincian snapshot tidak diubah oleh transisi status.
  Future<OrderRecord> transitionOrder(
    OwnerOrderTransition input, {
    required String mutationId,
  });
}

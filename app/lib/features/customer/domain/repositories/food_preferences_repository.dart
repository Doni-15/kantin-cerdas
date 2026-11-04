import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';

abstract interface class FoodPreferencesRepository {
  /// True hanya jika save, CAS, dedupe dan lookup receipt sudah didukung adapter.
  bool get isSaveConfigured;

  /// Null hanya setelah layanan memastikan belum ada record milik sesi aktif.
  Future<FoodPreferencesSnapshot?> getMyPreferences();

  /// Akun berasal dari sesi terverifikasi. null expectedVersion = create-if-absent;
  /// selain itu CAS atomik. Setiap perubahan menaikkan versi.
  /// customerId+mutationId diikat ke payload asli; dedupe tidak membuat write kedua.
  /// Respons berasal dari commit nyata, bukan echo input. Error definitif hanya
  /// jika tidak ada commit/late commit. Timeout/invalid response tetap unknown.
  Future<FoodPreferencesSnapshot> saveMyPreferences(
    FoodPreferencesUpdate update, {
    required String mutationId,
  });

  /// Lookup tidak menulis ulang preferensi. Receipt applied immutable membawa
  /// snapshot pada commit request ini. notApplied hanya jika ID disegel terhadap
  /// late commit; ID tidak ditemukan tanpa seal tetap pending. Retensi receipt
  /// dan dedupe wajib disepakati sebelum mengaktifkan adapter.
  Future<FoodPreferencesLookup> lookupSave({required String mutationId});
}

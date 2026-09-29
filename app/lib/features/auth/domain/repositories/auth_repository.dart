import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';

/// Semua method melempar AuthFailure saat gagal.
abstract interface class AuthRepository {
  Future<User> login({required String identifier, required String password});

  Future<User> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });

  /// Memulihkan user dari token tersimpan. Mengembalikan null jika tidak ada session valid.
  Future<User?> restoreSession();

  /// Menghapus session. Selalu menghapus token lokal, walau server gagal dihubungi.
  Future<void> logout();

  /// Mengubah password akun yang sedang login.
  /// Melempar InvalidCurrentPasswordFailure jika password saat ini salah.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

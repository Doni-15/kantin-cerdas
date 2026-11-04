import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/auth_tokens.dart';
import 'package:kantin_cerdas/core/session/session_user.dart';

typedef SessionTokenRefresher =
    Future<AuthTokens?> Function(String refreshToken);

abstract interface class AuthRepository {
  Future<User> login({required String identifier, required String password});

  Future<User> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });

  /// Meminta email pemulihan tanpa login dan tanpa mengubah sesi lokal.
  /// Selesai hanya setelah layanan mengakui permintaan; bukan bukti email
  /// terdaftar atau email sudah sampai. Tidak mengirim ulang otomatis.
  Future<void> requestPasswordReset({required String email});

  Future<User?> restoreSession();

  /// Selesai setelah token lokal dihapus; gagal storage tidak berarti sukses.
  /// Pencabutan sesi server berjalan terpisah sebagai best effort.
  Future<void> logout();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Memperbarui atau menghapus (`avatarUrl == null`) foto profil pengguna
  /// yang sedang aktif dan mengembalikan profil pengguna terbaru.
  Future<User> updateProfileAvatar({required String? avatarUrl});
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider must be overridden via production or test overrides.',
  );
});

final authTokenRefresherProvider = Provider<SessionTokenRefresher?>((ref) {
  return null;
});

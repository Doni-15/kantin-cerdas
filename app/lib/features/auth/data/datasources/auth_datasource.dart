import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';

abstract interface class AuthDataSource {
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  });

  /// Mendaftarkan akun pelanggan.
  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });

  /// Respons harus netral untuk email terdaftar maupun tidak terdaftar.
  /// Tidak membawa token sesi dan tidak mengembalikan keberadaan akun.
  Future<void> requestPasswordReset({required String email});

  /// Mengambil pengguna yang terhubung dengan token akses.
  Future<UserModel> getCurrentUser({required String accessToken});

  /// Memperbarui pasangan token sesi menggunakan refresh token yang masih berlaku.
  Future<LoginResponseModel> refreshSession({required String refreshToken});

  /// Meminta perubahan password pengguna yang sedang login.
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  });

  /// Memperbarui atau menghapus (`avatarUrl == null`) foto profil pengguna.
  Future<UserModel> updateProfileAvatar({
    required String accessToken,
    required String? avatarUrl,
  });

  /// Cabut hanya sesi milik token argumen ini. Jangan menggunakan token
  /// global yang dapat berubah atau mencabut semua sesi akun.
  /// Repository memanggilnya tanpa menahan penghapusan sesi lokal.
  Future<void> logout({required String accessToken, String? refreshToken});
}

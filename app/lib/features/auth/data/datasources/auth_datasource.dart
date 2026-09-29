import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';

/// Kontrak sumber data Auth. Dummy dan API harus memenuhi kontrak yang sama.
///
/// Semua implementasi melempar `ApiException` untuk error HTTP/jaringan.
abstract interface class AuthDataSource {
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  });

  /// POST /auth/register
  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });

  /// GET /auth/me
  Future<UserModel> getCurrentUser({required String accessToken});

  /// POST /auth/change-password  (butuh access token)
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  });

  /// POST /auth/logout
  Future<void> logout({required String refreshToken});
}

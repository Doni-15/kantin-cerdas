import 'dart:typed_data';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';

abstract interface class AuthDataSource {
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  });

  Future<bool> isEmailAvailable({required String email});

  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
    Uint8List? avatarBytes,
  });

  Future<void> requestPasswordReset({required String email});
  Future<UserModel> getCurrentUser({required String accessToken});
  Future<LoginResponseModel> refreshSession({required String refreshToken});

  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  });

  Future<UserModel> updateProfileAvatar({
    required String accessToken,
    required String? avatarUrl,
  });

  Future<void> logout({required String accessToken, String? refreshToken});
}

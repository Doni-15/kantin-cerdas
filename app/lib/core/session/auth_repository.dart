import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/auth_tokens.dart';
import 'package:kantin_cerdas/core/session/session_user.dart';

typedef SessionTokenRefresher = Future<AuthTokens?> Function(String refreshToken);

abstract interface class AuthRepository {
  Future<User> login({required String identifier, required String password});

  Future<bool> isEmailAvailable({required String email});

  Future<User> register({
    required String name,
    required String username,
    required String email,
    required String password,
    Uint8List? avatarBytes,
  });

  Future<void> requestPasswordReset({required String email});

  Future<User?> restoreSession();

  Future<void> logout();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

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
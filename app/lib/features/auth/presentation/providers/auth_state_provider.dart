import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';

final authStateProvider = NotifierProvider<AuthStateNotifier, User?>(
  AuthStateNotifier.new,
);

/// Menyimpan user yang sedang login. null = belum login.
/// Router dapat memakai provider ini untuk redirect.
class AuthStateNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  void setUser(User user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }

  /// Panggil saat startup/splash untuk memulihkan session dari token tersimpan.
  Future<void> restoreSession() async {
    try {
      state = await ref.read(restoreSessionUseCaseProvider).execute();
    } on AuthFailure {
      // Server tidak terjangkau saat startup: token tetap tersimpan,
      // user diarahkan ke login dan bisa mencoba lagi.
      state = null;
    }
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider).execute();
    state = null;
  }
}

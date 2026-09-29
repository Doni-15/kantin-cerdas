import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

/// autoDispose: state (error/data) ter-reset setiap halaman login ditutup.
final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, User?>(
  LoginController.new,
);

class LoginController extends AsyncNotifier<User?> {
  bool _disposed = false;

  @override
  Future<User?> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    return null;
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final user = await ref.read(loginUseCaseProvider).execute(
            identifier: identifier,
            password: password,
          );

      // Halaman ditutup saat request berjalan: jangan sentuh state/ref lagi.
      if (_disposed) {
        return;
      }

      // Auth state di-set di sini (bukan di UI).
      ref.read(authStateProvider.notifier).setUser(user);

      state = AsyncData(user);
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }

      state = AsyncError(error, stackTrace);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';

/// autoDispose: state (error/data) ter-reset setiap halaman registrasi ditutup.
final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, User?>(
  RegisterController.new,
);

class RegisterController extends AsyncNotifier<User?> {
  bool _disposed = false;

  @override
  Future<User?> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    return null;
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final user = await ref.read(registerUseCaseProvider).execute(
            name: name,
            username: username,
            email: email,
            password: password,
          );

      if (_disposed) {
        return;
      }

      state = AsyncData(user);
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }

      state = AsyncError(error, stackTrace);
    }
  }
}

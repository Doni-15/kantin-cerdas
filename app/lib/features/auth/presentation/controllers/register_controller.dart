import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';

final registerControllerProvider = AsyncNotifierProvider<RegisterController, User?>(
  RegisterController.new,
);

class RegisterController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
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
      final useCase = ref.read(registerUseCaseProvider);

      final user = await useCase.execute(
        name: name,
        username: username,
        email: email,
        password: password,
      );

      state = AsyncData(user);
    } 
    catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }
}
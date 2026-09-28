import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';

final loginControllerProvider = AsyncNotifierProvider<LoginController, User?>(
  LoginController.new,
);

class LoginController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return null;
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final useCase = ref.read(loginUseCaseProvider);
      final user = await useCase.execute(
        username: username,
        password: password,
      );

      state = AsyncData(user);
    } 
    catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
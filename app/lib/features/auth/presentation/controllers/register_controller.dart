import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';

final registerControllerProvider =
    NotifierProvider.autoDispose<RegisterController, AsyncValue<User?>>(
      RegisterController.new,
    );

class RegisterController extends Notifier<AsyncValue<User?>> {
  @override
  AsyncValue<User?> build() {
    return const AsyncData<User?>(null);
  }

  /// Hasil registrasi disimpan pada state provider.
  Future<void> submit({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    if (state.isLoading || state.asData?.value != null) {
      return;
    }

    final currentRef = ref;
    state = const AsyncLoading<User?>();

    final result = await AsyncValue.guard<User?>(() {
      final registerUseCase = currentRef.read(registerUseCaseProvider);

      return registerUseCase.execute(
        name: name,
        username: username,
        email: email,
        password: password,
      );
    });

    if (!currentRef.mounted) return;
    state = result;
  }
}

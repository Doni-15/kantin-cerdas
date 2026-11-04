import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

final changePasswordControllerProvider =
    NotifierProvider.autoDispose<ChangePasswordController, AsyncValue<void>>(
      ChangePasswordController.new,
    );

class ChangePasswordController extends Notifier<AsyncValue<void>> {
  int _generation = 0;

  @override
  AsyncValue<void> build() {
    ++_generation;
    ref.listen(authStateProvider, (previous, next) {
      if (next.isLoading ||
          next.hasError ||
          previous?.asData?.value?.id != next.asData?.value?.id) {
        ++_generation;
        state = const AsyncData<void>(null);
      }
    });
    return const AsyncData<void>(null);
  }

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.isLoading) return;
    final auth = ref.read(authStateProvider.notifier);
    final session = auth.sessionGeneration;
    final generation = ++_generation;
    state = const AsyncLoading<void>();
    final result = await AsyncValue.guard<void>(
      () => auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    if (!ref.mounted ||
        generation != _generation ||
        session != auth.sessionGeneration) {
      return;
    }
    state = result;
  }
}

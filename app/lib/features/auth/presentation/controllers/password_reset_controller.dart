import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/password_reset_state.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

final passwordResetControllerProvider =
    NotifierProvider.autoDispose<PasswordResetController, PasswordResetState>(
      PasswordResetController.new,
    );

class PasswordResetController extends Notifier<PasswordResetState> {
  int _generation = 0;

  @override
  PasswordResetState build() {
    ++_generation;
    ref.listen(authStateProvider, (previous, next) {
      if (next.asData?.value?.isActive == true) {
        ++_generation;
        state = const PasswordResetState.idle();
      }
    });
    return const PasswordResetState.idle();
  }

  Future<void> submit({required String email}) async {
    if (state.isSubmitting ||
        state.isAcknowledged ||
        state.failure is AuthNotConfiguredFailure ||
        ref.read(authStateProvider).asData?.value?.isActive == true) {
      return;
    }
    final useCase = ref.read(requestPasswordResetUseCaseProvider);
    final session = ref.read(authStateProvider.notifier).sessionGeneration;
    final generation = ++_generation;
    state = const PasswordResetState.submitting();
    PasswordResetState result;
    try {
      await useCase.execute(email: email);
      result = const PasswordResetState.acknowledged();
    } on AuthFailure catch (failure) {
      result = PasswordResetState.failed(failure);
    } catch (_) {
      result = const PasswordResetState.failed(
        AuthPasswordResetUnconfirmedFailure(),
      );
    }
    if (!ref.mounted || generation != _generation) {
      return;
    }
    if (session != ref.read(authStateProvider.notifier).sessionGeneration) {
      state = const PasswordResetState.idle();
      return;
    }
    state = result;
  }

  void editEmail() {
    if (state.isSubmitting) {
      return;
    }
    ++_generation;
    state = const PasswordResetState.idle();
  }
}

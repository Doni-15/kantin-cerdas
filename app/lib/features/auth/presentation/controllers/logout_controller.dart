import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

final logoutControllerProvider =
    NotifierProvider.autoDispose<LogoutController, AsyncValue<void>>(
      LogoutController.new,
    );

class LogoutController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData<void>(null);
  }

  Future<void> submit() async {
    if (state.isLoading) {
      return;
    }

    final currentRef = ref;

    state = const AsyncLoading<void>();

    final result = await AsyncValue.guard<void>(() async {
      final auth = currentRef.read(authStateProvider.notifier);

      await auth.logout();
    });

    // Operasi logout tetap diselesaikan melalui auth state.
    // State UI hanya diperbarui jika controller masih aktif.
    if (!currentRef.mounted) {
      return;
    }

    state = result;
  }
}

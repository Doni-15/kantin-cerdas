import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, AsyncValue<void>>(
      LoginController.new,
    );

class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData<void>(null);
  }

  /// Hasil pengiriman form disimpan pada state provider.
  Future<void> submit({
    required String identifier,
    required String password,
  }) async {
    if (state.isLoading) return;

    final currentRef = ref;
    state = const AsyncLoading<void>();

    final result = await AsyncValue.guard<void>(() async {
      final auth = currentRef.read(authStateProvider.notifier);

      await auth.login(identifier: identifier, password: password);
    });

    if (!currentRef.mounted) return;

    state = result;
  }
}

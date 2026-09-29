import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';

/// autoDispose: state (error/sukses) ter-reset setiap halaman ditutup.
///
/// Nilai state: false = belum berhasil, true = password berhasil diubah.
final changePasswordControllerProvider =
    AsyncNotifierProvider.autoDispose<ChangePasswordController, bool>(
      ChangePasswordController.new,
    );

class ChangePasswordController extends AsyncNotifier<bool> {
  bool _disposed = false;

  @override
  FutureOr<bool> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    return false;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(changePasswordUseCaseProvider)
          .execute(currentPassword: currentPassword, newPassword: newPassword);

      // Halaman ditutup saat request berjalan: jangan sentuh state lagi.
      if (_disposed) {
        return;
      }

      state = const AsyncData(true);
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }

      state = AsyncError(error, stackTrace);
    }
  }
}

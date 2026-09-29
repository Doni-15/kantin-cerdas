import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_providers.dart';

/// Pengajuan kantin milik user yang sedang login (null = belum mengajukan).
final canteenApplicationProvider =
    AsyncNotifierProvider<CanteenApplicationNotifier, CanteenApplication?>(
  CanteenApplicationNotifier.new,
);

class CanteenApplicationNotifier extends AsyncNotifier<CanteenApplication?> {
  @override
  Future<CanteenApplication?> build() async {
    // Ikut akun yang login: logout / ganti akun me-reset state lalu memuat ulang,
    // sehingga pengajuan satu user tidak terlihat oleh user lain.
    final userId = ref.watch(authStateProvider.select((user) => user?.id));

    if (userId == null) {
      return null;
    }

    return ref.watch(canteenApplicationRepositoryProvider).getMyApplication();
  }

  /// Dipanggil setelah pengajuan berhasil dikirim.
  void setApplication(CanteenApplication application) {
    state = AsyncData(application);
  }

  /// Simulasi review admin. Pindahkan ke feature admin saat feature itu dibuat.
  Future<void> updateStatus(
    CanteenApplicationStatus status, {
    String? rejectionReason,
  }) async {
    final application = _currentApplication;

    if (application == null) {
      return;
    }

    final updated =
        await ref.read(canteenApplicationRepositoryProvider).updateStatus(
              id: application.id,
              status: status,
              rejectionReason: rejectionReason,
            );

    state = AsyncData(updated);
  }

  Future<void> clearApplication() async {
    await ref.read(canteenApplicationRepositoryProvider).deleteMyApplication();

    state = const AsyncData(null);
  }

  CanteenApplication? get _currentApplication {
    return switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }
}

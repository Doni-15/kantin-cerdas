import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_providers.dart';

/// autoDispose: state (error/data) ter-reset setiap layar form ditutup.
final canteenApplicationSubmitProvider = AsyncNotifierProvider.autoDispose<
    CanteenApplicationSubmitController, CanteenApplication?>(
  CanteenApplicationSubmitController.new,
);

class CanteenApplicationSubmitController
    extends AsyncNotifier<CanteenApplication?> {
  @override
  Future<CanteenApplication?> build() async {
    return null;
  }

  Future<void> submit({
    required String name,
    required String description,
    required String address,
  }) async {
    state = const AsyncLoading();

    // Tahan provider selama request berjalan: walau layar ditutup, hasilnya
    // tetap masuk ke state "pengajuan saya".
    final keepAlive = ref.keepAlive();

    try {
      final application =
          await ref.read(submitCanteenApplicationUseCaseProvider).execute(
                name: name,
                description: description,
                address: address,
              );

      ref.read(canteenApplicationProvider.notifier).setApplication(application);

      state = AsyncData(application);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      keepAlive.close();
    }
  }
}

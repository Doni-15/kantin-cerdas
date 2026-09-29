import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';

/// Semua method melempar CanteenApplicationFailure saat gagal.
/// User yang sedang login dikenali Backend dari token, bukan dikirim dari UI.
abstract interface class CanteenApplicationRepository {
  /// GET /canteen-applications/me. Null jika belum pernah mengajukan.
  Future<CanteenApplication?> getMyApplication();

  /// POST /canteen-applications
  Future<CanteenApplication> submit({
    required String name,
    required String description,
    required String address,
  });

  /// PATCH /canteen-applications/{id}/status
  ///
  /// Ini aksi milik Admin (review). Sementara ada di sini untuk mensimulasikan
  /// review; pindahkan ke feature admin saat feature itu dibuat.
  Future<CanteenApplication> updateStatus({
    required String id,
    required CanteenApplicationStatus status,
    String? rejectionReason,
  });

  /// DELETE /canteen-applications/me
  Future<void> deleteMyApplication();
}

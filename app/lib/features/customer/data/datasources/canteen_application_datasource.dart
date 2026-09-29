import 'package:kantin_cerdas/features/customer/data/models/canteen_application_model.dart';

/// Kontrak sumber data pengajuan kantin. Dummy dan API harus memenuhi kontrak yang sama.
///
/// Semua implementasi melempar `ApiException` untuk error HTTP/jaringan.
abstract interface class CanteenApplicationDataSource {
  /// GET /canteen-applications/me. Null jika belum pernah mengajukan.
  Future<CanteenApplicationModel?> getMyApplication();

  /// POST /canteen-applications
  Future<CanteenApplicationModel> submit({
    required String name,
    required String description,
    required String address,
  });

  /// PATCH /canteen-applications/{id}/status  (aksi Admin)
  Future<CanteenApplicationModel> updateStatus({
    required String id,
    required String status,
    String? rejectionReason,
  });

  /// DELETE /canteen-applications/me
  Future<void> deleteMyApplication();
}

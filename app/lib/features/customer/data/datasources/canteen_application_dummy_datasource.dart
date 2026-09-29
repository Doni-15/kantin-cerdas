import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/canteen_application_model.dart';
import 'package:kantin_cerdas/features/customer/domain/validators/canteen_application_validator.dart';

/// Meniru Backend pengajuan kantin.
///
/// - Bicara dalam bentuk JSON (snake_case) lalu di-parse dengan `fromJson`.
/// - Data disimpan PER USER; user dikenali lewat [currentUserId] (pengganti token).
/// - Id, status awal, dan waktu pengajuan ditentukan di sini, seperti server.
/// - Melempar `ApiException` dengan status code seperti Backend.
///
/// Skenario error (isi nama kantin saat mengajukan):
///   `offline`  -> tidak ada koneksi
///   `timeout`  -> request timeout
///   `error500` -> server error
class CanteenApplicationDummyDataSource implements CanteenApplicationDataSource {
  CanteenApplicationDummyDataSource({
    required this.currentUserId,
    this.latency = const Duration(seconds: 1),
    this.storage,
  }) {
    _restore();
  }

  /// Siapa yang sedang login. Backend nyata membaca ini dari access token,
  /// jadi parameter ini hilang saat dummy diganti API.
  final String? Function() currentUserId;

  /// Jeda jaringan buatan. Gunakan `Duration.zero` di unit test.
  final Duration latency;

  /// Jika diisi, pengajuan disimpan di sini sehingga bertahan setelah
  /// aplikasi ditutup (meniru database Backend).
  final LocalStorage? storage;

  final Map<String, Map<String, dynamic>> _applicationsByUser = {};

  int _nextId = 1;

  void _restore() {
    final state = storage?.readJson(StorageKeys.canteenApplicationDummyState);

    if (state == null) {
      return;
    }

    try {
      final applications = <String, Map<String, dynamic>>{};
      final raw = state['applications'] as Map<String, dynamic>;

      for (final entry in raw.entries) {
        applications[entry.key] = Map<String, dynamic>.from(entry.value as Map);
      }

      final nextId = state['next_id'] as int;

      _applicationsByUser
        ..clear()
        ..addAll(applications);
      _nextId = nextId;
    } on Object {
      // Data tersimpan rusak: mulai dari kondisi awal.
    }
  }

  Future<void> _persist() async {
    await storage?.writeJson(StorageKeys.canteenApplicationDummyState, {
      'next_id': _nextId,
      'applications': _applicationsByUser,
    });
  }

  @override
  Future<CanteenApplicationModel?> getMyApplication() async {
    await Future<void>.delayed(latency);

    final json = _applicationsByUser[_requireUserId()];

    if (json == null) {
      return null;
    }

    return CanteenApplicationModel.fromJson(
      Map<String, dynamic>.from(json),
    );
  }

  @override
  Future<CanteenApplicationModel> submit({
    required String name,
    required String description,
    required String address,
  }) async {
    await Future<void>.delayed(latency);
    _throwIfSimulated(name);

    final userId = _requireUserId();

    final normalizedName = name.trim();
    final normalizedDescription = description.trim();
    final normalizedAddress = address.trim();

    // Validasi sisi server (422). Aturan sama dengan yang dipakai UI/UseCase.
    final fieldErrors = <String, String>{};

    final nameError = CanteenApplicationValidator.name(normalizedName);
    if (nameError != null) fieldErrors['name'] = nameError;

    final descriptionError =
        CanteenApplicationValidator.description(normalizedDescription);
    if (descriptionError != null) fieldErrors['description'] = descriptionError;

    final addressError =
        CanteenApplicationValidator.address(normalizedAddress);
    if (addressError != null) fieldErrors['address'] = addressError;

    if (fieldErrors.isNotEmpty) {
      throw ApiException(
        statusCode: 422,
        code: ApiErrorCode.validationError,
        fieldErrors: fieldErrors,
      );
    }

    final json = <String, dynamic>{
      'id': _nextId++,
      'customer_id': userId,
      'name': normalizedName,
      'description': normalizedDescription,
      'address': normalizedAddress,
      'status': 'submitted',
      'rejection_reason': null,
      'submitted_at': DateTime.now().toIso8601String(),
    };

    // Pengajuan baru menggantikan yang lama (perilaku sebelum refactor).
    _applicationsByUser[userId] = json;
    await _persist();

    return CanteenApplicationModel.fromJson(
      Map<String, dynamic>.from(json),
    );
  }

  @override
  Future<CanteenApplicationModel> updateStatus({
    required String id,
    required String status,
    String? rejectionReason,
  }) async {
    await Future<void>.delayed(latency);

    final entry = _applicationsByUser.entries
        .where((entry) => entry.value['id'].toString() == id)
        .firstOrNull;

    if (entry == null) {
      throw const ApiException(statusCode: 404, code: 'not_found');
    }

    entry.value['status'] = status;
    entry.value['rejection_reason'] = rejectionReason;
    await _persist();

    return CanteenApplicationModel.fromJson(
      Map<String, dynamic>.from(entry.value),
    );
  }

  @override
  Future<void> deleteMyApplication() async {
    await Future<void>.delayed(latency);

    _applicationsByUser.remove(_requireUserId());
    await _persist();
  }

  String _requireUserId() {
    final userId = currentUserId();

    if (userId == null) {
      throw const ApiException(
        statusCode: 401,
        code: ApiErrorCode.tokenInvalid,
      );
    }

    return userId;
  }

  void _throwIfSimulated(String key) {
    switch (key.trim().toLowerCase()) {
      case 'offline':
        throw const ApiException(
          statusCode: 0,
          code: ApiErrorCode.network,
        );
      case 'timeout':
        throw const ApiException(
          statusCode: 0,
          code: ApiErrorCode.timeout,
        );
      case 'error500':
        throw const ApiException(
          statusCode: 500,
          code: ApiErrorCode.serverError,
        );
    }
  }
}

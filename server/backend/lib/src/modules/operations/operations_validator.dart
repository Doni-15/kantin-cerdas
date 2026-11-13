import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';

/// Input tervalidasi untuk `GET /v1/operations/<family>/<requestId>`.
final class ValidatedOperationLookupInput {
  final String family;
  final String requestId;

  const ValidatedOperationLookupInput({
    required this.family,
    required this.requestId,
  });
}

/// Validator parameter path untuk pemulihan mutasi terjurnal (`/v1/operations/*`).
final class OperationsValidator {
  const OperationsValidator._();

  /// Keenam keluarga mutasi terjurnal klien sesuai enum `public.mutation_family`
  /// di `001_extensions_types.sql` dan `005_idempotency.sql`.
  static const Set<String> allowedFamilies = <String>{
    'orders',
    'order-cancellations',
    'canteen-applications',
    'food-preferences',
    'owner-mutations',
    'admin-mutations',
  };

  static ValidatedOperationLookupInput validateLookup({
    required String? rawFamily,
    required String? rawRequestId,
  }) {
    final family = _decodePathParam(rawFamily);
    if (!allowedFamilies.contains(family)) {
      throw ApiException.notFound(
        'Keluarga operasi "$family" tidak ditemukan.',
        'ENDPOINT_NOT_FOUND',
      );
    }

    final requestId = _decodePathParam(rawRequestId);
    if (!SecurityConstants.idempotencyKeyPattern.hasMatch(requestId)) {
      throw ApiException.unprocessable(
        'Parameter requestId wajib berupa 48 karakter hex huruf kecil.',
        code: 'INVALID_INPUT',
      );
    }

    return ValidatedOperationLookupInput(
      family: family,
      requestId: requestId,
    );
  }

  static String _decodePathParam(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.contains('%')) return trimmed;
    try {
      return Uri.decodeComponent(trimmed).trim();
    } on FormatException {
      throw ApiException.badRequest(
        'Parameter URL mengandung encoding UTF-8 yang tidak valid.',
        code: 'INVALID_INPUT',
      );
    } on ArgumentError {
      throw ApiException.badRequest(
        'Parameter URL mengandung encoding yang tidak valid.',
        code: 'INVALID_INPUT',
      );
    }
  }
}
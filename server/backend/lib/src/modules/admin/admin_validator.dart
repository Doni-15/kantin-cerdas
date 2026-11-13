import 'package:characters/characters.dart';

import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/utils/json_types.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/admin_validated_input.dart';

export 'package:kantin_cerdas_backend/src/modules/admin/admin_validated_input.dart';

/// Validator Zero-Trust untuk seluruh endpoint modul Admin (`/v1/admin/*`).
final class AdminValidator {
  const AdminValidator._();

  static const int _defaultLimit = 30;
  static const int _minLimit = 1;
  static const int _maxLimit = 100;
  static const int _maxSearchGraphemes = 120;
  static const int _maxSearchCodePoints = 480;
  static const int _maxReasonGraphemes = 300;
  static const int _maxReasonCodePoints = 1200;

  static final RegExp _userIdPattern = RegExp(r'^usr_[a-f0-9]{32}$');
  static final RegExp _applicationIdPattern = RegExp(r'^app_[a-f0-9]{32}$');

  static const Set<String> _allowedApplicationStatuses = <String>{
    'submitted',
    'reviewing',
    'approved',
    'rejected',
  };

  static const Set<String> _allowedReviewDecisions = <String>{
    'approved',
    'rejected',
  };

  /// 1. Validasi query `GET /v1/admin/users?search=...&cursor=...&limit=...`.
  static ValidatedListAdminUsersInput validateListUsers(
    Map<String, String> queryParams,
  ) {
    final rawSearch = (queryParams['search'] ?? '').trim();
    if (rawSearch.characters.length > _maxSearchGraphemes ||
        rawSearch.runes.length > _maxSearchCodePoints) {
      throw ApiException.unprocessable(
        'Kata kunci pencarian maksimal 120 karakter.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'search': 'Kata kunci pencarian maksimal 120 karakter.',
        },
      );
    }

    final limit = _parseLimit(queryParams['limit']);
    final cursor = _parseKeysetCursor(
      queryParams['cursor'],
      idPattern: _userIdPattern,
    );

    return ValidatedListAdminUsersInput(
      search: rawSearch,
      cursor: cursor,
      limit: limit,
    );
  }

  /// 2. Validasi parameter path `userId` pada `GET /v1/admin/users/<userId>`.
  static String validateUserId(String? rawUserId) {
    final decoded = _decodePathParam(rawUserId);
    if (!_userIdPattern.hasMatch(decoded)) {
      throw ApiException.unprocessable(
        'Format identitas pengguna (userId) tidak valid.',
        code: 'INVALID_INPUT',
      );
    }
    return decoded;
  }

  /// 3. Validasi `POST /v1/admin/users/<userId>/access`.
  /// Selaras dengan `AdminUserAccessChange` di Flutter dan `rpc_admin_set_user_access` di `008_rpc_admin.sql`.
  static ValidatedSetUserAccessInput validateSetUserAccess({
    required String? rawTargetUserId,
    required String? idempotencyKeyHeader,
    required String actorId,
    required JsonMap body,
  }) {
    final targetUserId = validateUserId(rawTargetUserId);
    if (targetUserId == actorId) {
      throw ApiException.forbidden(
        'Admin tidak dapat mengubah status akses akunnya sendiri.',
        'FORBIDDEN',
      );
    }

    final mutationId = _resolveMutationId(
      headerValue: idempotencyKeyHeader,
      bodyValue: body['mutation_id'] ?? body['mutationId'],
    );

    final fieldErrors = <String, String>{};

    final rawExpectedVersion =
        body['expected_version'] ?? body['expectedVersion'];
    int? expectedVersion;
    if (rawExpectedVersion is int && rawExpectedVersion >= 1) {
      expectedVersion = rawExpectedVersion;
    } else {
      fieldErrors['expected_version'] =
          'Field expected_version wajib berupa bilangan bulat >= 1.';
    }

    final rawIsActive = body['is_active'] ?? body['isActive'];
    bool? isActive;
    if (rawIsActive is bool) {
      isActive = rawIsActive;
    } else {
      fieldErrors['is_active'] =
          'Field is_active wajib berupa boolean (true atau false).';
    }

    final reasonError = _validateRequiredReason(
      body['reason'],
      emptyMessage: 'Alasan perubahan akses wajib diisi.',
      maxMessage: 'Alasan perubahan akses maksimal 300 karakter.',
    );
    if (reasonError != null) {
      fieldErrors['reason'] = reasonError;
    }

    if (fieldErrors.isNotEmpty) {
      throw ApiException.unprocessable(
        fieldErrors.values.first,
        code: fieldErrors.keys.first == 'reason'
            ? 'INVALID_REASON'
            : 'INVALID_INPUT',
        fieldErrors: fieldErrors,
      );
    }

    return ValidatedSetUserAccessInput(
      mutationId: mutationId,
      targetUserId: targetUserId,
      expectedVersion: expectedVersion!,
      isActive: isActive!,
      reason: _readString(body['reason']).trim(),
    );
  }

  /// 4. Validasi query `GET /v1/admin/applications?status=...&cursor=...&limit=...`.
  static ValidatedListAdminApplicationsInput validateListApplications(
    Map<String, String> queryParams,
  ) {
    final rawStatus = (queryParams['status'] ?? '').trim();
    String? status;
    if (rawStatus.isNotEmpty) {
      if (!_allowedApplicationStatuses.contains(rawStatus)) {
        throw ApiException.unprocessable(
          'Filter status pengajuan tidak valid.',
          code: 'INVALID_INPUT',
          fieldErrors: const {'status': 'Status pengajuan tidak dikenali.'},
        );
      }
      status = rawStatus;
    }

    final limit = _parseLimit(queryParams['limit']);
    final cursor = _parseKeysetCursor(
      queryParams['cursor'],
      idPattern: _applicationIdPattern,
    );

    return ValidatedListAdminApplicationsInput(
      status: status,
      cursor: cursor,
      limit: limit,
    );
  }

  /// 5. Validasi parameter path `applicationId` pada `GET /v1/admin/applications/<applicationId>`.
  static String validateApplicationId(String? rawApplicationId) {
    final decoded = _decodePathParam(rawApplicationId);
    if (!_applicationIdPattern.hasMatch(decoded)) {
      throw ApiException.unprocessable(
        'Format identitas pengajuan (applicationId) tidak valid.',
        code: 'INVALID_INPUT',
      );
    }
    return decoded;
  }

  /// 6. Validasi `POST /v1/admin/applications/<applicationId>/review`.
  /// Selaras dengan `AdminApplicationReview` di Flutter dan `rpc_admin_review_application` di `008_rpc_admin.sql`.
  static ValidatedReviewApplicationInput validateReviewApplication({
    required String? rawApplicationId,
    required String? idempotencyKeyHeader,
    required JsonMap body,
  }) {
    final applicationId = validateApplicationId(rawApplicationId);
    final mutationId = _resolveMutationId(
      headerValue: idempotencyKeyHeader,
      bodyValue: body['mutation_id'] ?? body['mutationId'],
    );

    final rawExpectedVersion =
        body['expected_version'] ?? body['expectedVersion'];
    if (rawExpectedVersion is! int || rawExpectedVersion < 1) {
      throw ApiException.unprocessable(
        'Field expected_version wajib berupa bilangan bulat >= 1.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'expected_version': 'Versi pengajuan tidak valid.',
        },
      );
    }

    final rawDecision = _readString(body['status'] ?? body['decision']).trim();
    if (!_allowedReviewDecisions.contains(rawDecision)) {
      throw ApiException.unprocessable(
        'Keputusan pengajuan hanya boleh approved atau rejected.',
        code: 'INVALID_DECISION',
        fieldErrors: const {
          'status': 'Pilih approved atau rejected.',
        },
      );
    }

    final rawReasonObj = body['reason'];
    if (rawReasonObj != null && rawReasonObj is! String) {
      throw ApiException.unprocessable(
        'Field reason harus berupa teks atau null.',
        code: 'INVALID_REASON',
        fieldErrors: const {'reason': 'Format alasan tidak valid.'},
      );
    }

    final trimmedReason = (rawReasonObj as String?)?.trim() ?? '';
    if (rawDecision == 'approved' && trimmedReason.isNotEmpty) {
      throw ApiException.unprocessable(
        'Keputusan approved tidak boleh menyertakan alasan penolakan.',
        code: 'INVALID_REASON',
        fieldErrors: const {
          'reason': 'Kosongkan alasan saat menyetujui pengajuan.',
        },
      );
    }

    if (rawDecision == 'rejected') {
      final reasonError = _validateRequiredReason(
        trimmedReason,
        emptyMessage: 'Penolakan pengajuan wajib menyertakan alasan.',
        maxMessage: 'Alasan penolakan maksimal 300 karakter.',
      );
      if (reasonError != null) {
        throw ApiException.unprocessable(
          reasonError,
          code: 'INVALID_REASON',
          fieldErrors: <String, String>{'reason': reasonError},
        );
      }
    }

    return ValidatedReviewApplicationInput(
      mutationId: mutationId,
      applicationId: applicationId,
      expectedVersion: rawExpectedVersion,
      decision: rawDecision,
      reason: trimmedReason.isEmpty ? null : trimmedReason,
    );
  }

  static String? _validateRequiredReason(
    Object? rawValue, {
    required String emptyMessage,
    required String maxMessage,
  }) {
    final trimmed = _readString(rawValue).trim();
    if (trimmed.isEmpty) {
      return emptyMessage;
    }
    if (trimmed.characters.length > _maxReasonGraphemes ||
        trimmed.runes.length > _maxReasonCodePoints) {
      return maxMessage;
    }
    return null;
  }

  static int _parseLimit(String? rawLimit) {
    final trimmed = (rawLimit ?? '').trim();
    if (trimmed.isEmpty) return _defaultLimit;

    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < _minLimit || parsed > _maxLimit) {
      throw ApiException.unprocessable(
        'Parameter limit wajib berupa bilangan bulat antara $_minLimit dan $_maxLimit.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'limit': 'Batas halaman harus antara 1 dan 100.'},
      );
    }
    return parsed;
  }

  /// Mendekode token kursor keyset `<ISO-8601-UTC>|<entity_id>` sesuai `009_read_functions.sql`.
  static ValidatedKeysetCursor? _parseKeysetCursor(
    String? rawCursor, {
    required RegExp idPattern,
  }) {
    final trimmed = (rawCursor ?? '').trim();
    if (trimmed.isEmpty) return null;

    final sepIndex = trimmed.indexOf('|');
    if (sepIndex <= 0 || sepIndex >= trimmed.length - 1) {
      throw ApiException.unprocessable(
        'Format kursor paginasi tidak valid.',
        code: 'INVALID_CURSOR',
      );
    }

    final tsPart = trimmed.substring(0, sepIndex).trim();
    final idPart = trimmed.substring(sepIndex + 1).trim();

    final parsedTs = DateTime.tryParse(tsPart);
    if (parsedTs == null ||
        !tsPart.endsWith('Z') ||
        !idPattern.hasMatch(idPart)) {
      throw ApiException.unprocessable(
        'Token kursor paginasi rusak atau kedaluwarsa.',
        code: 'INVALID_CURSOR',
      );
    }

    return ValidatedKeysetCursor(
      cursorTsIso: tsPart,
      cursorId: idPart,
    );
  }

  static String _resolveMutationId({
    required String? headerValue,
    required Object? bodyValue,
  }) {
    final header = (headerValue ?? '').trim();
    final bodyStr = _readString(bodyValue).trim();

    if (header.isNotEmpty && bodyStr.isNotEmpty && header != bodyStr) {
      throw ApiException.unprocessable(
        'Header Idempotency-Key dan field mutation_id di body harus identik.',
        code: 'INVALID_INPUT',
      );
    }

    final effective = header.isNotEmpty ? header : bodyStr;
    if (!SecurityConstants.idempotencyKeyPattern.hasMatch(effective)) {
      throw ApiException.unprocessable(
        'Header Idempotency-Key (mutation_id) wajib berupa 48 karakter hex huruf kecil.',
        code: 'INVALID_INPUT',
      );
    }
    return effective;
  }

  /// Mendekode parameter path URL secara aman.
  /// Menangkap baik [ArgumentError] maupun [FormatException] (mis. byte UTF-8
  /// tidak valid seperti `%FF`) agar selalu menghasilkan 400 `INVALID_INPUT`.
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

  static String _readString(Object? value) {
    if (value is String) return value;
    return '';
  }
}
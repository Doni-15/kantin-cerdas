import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:shelf/shelf.dart';

String requireAdminUuid(String raw) {
  final value = tryNormalizeUuid(raw);
  if (value == null) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  return value;
}

String? optionalAdminUuidQuery(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return requireAdminUuid(raw);
}

Future<Map<String, Object?>> readAdminJsonBody(Request request) =>
    readJsonObjectBody(
      request,
      onUnsupportedMediaType: () =>
          const AdminFailure(AdminFailureCode.unsupportedMediaType),
      onTooLarge: () => const AdminFailure(AdminFailureCode.payloadTooLarge),
      onInvalidJson: () => const AdminFailure(AdminFailureCode.invalidInput),
    );

String readAdminRequiredText(
  Map<String, Object?> body,
  String field, {
  required int maxLength,
  bool allowNewlines = false,
}) {
  final value = body[field];
  if (value is! String) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  final trimmed = value.trim();
  final hasUnsafeControl = allowNewlines
      ? hasMultilineUnsafeControlChars(trimmed)
      : hasStrictControlChars(trimmed);
  if (trimmed.isEmpty || trimmed.runes.length > maxLength || hasUnsafeControl) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  return trimmed;
}

String? readAdminOptionalReason(Map<String, Object?> body, String field) {
  if (!body.containsKey(field) || body[field] == null) return null;
  final value = body[field];
  if (value is! String) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  final trimmed = value.trim();
  if (trimmed.runes.length > 500 || hasMultilineUnsafeControlChars(trimmed)) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  return trimmed.isEmpty ? null : trimmed;
}

bool readAdminRequiredBool(Map<String, Object?> body, String field) {
  final value = body[field];
  if (value is! bool) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  return value;
}

String? readAdminOptionalQueryText(String? raw, {int maxLength = 120}) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.runes.length > maxLength || hasStrictControlChars(trimmed)) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  return trimmed;
}

int readAdminLimit(String? raw, {int fallback = 30}) {
  if (raw == null || raw.isEmpty) return fallback;
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed < 1 || parsed > 100) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  return parsed;
}

int readAdminOffset(String? raw) {
  if (raw == null || raw.isEmpty) return 0;
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed < 0 || parsed > 100000) {
    throw const AdminFailure(AdminFailureCode.invalidInput);
  }
  return parsed;
}

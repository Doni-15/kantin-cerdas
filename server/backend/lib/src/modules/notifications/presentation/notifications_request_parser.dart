import 'dart:convert';

import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_errors.dart';
import 'package:shelf/shelf.dart';

Future<Map<String, Object?>> readNotificationJsonObject(Request request) async {
  final raw = await request.readAsString();
  if (raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, Object?>.from(decoded);
  } on FormatException {
    // Fall through to uniform validation error.
  }
  throw const NotificationFailure(
    NotificationFailureCode.invalidInput,
    'Body JSON tidak valid.',
  );
}

String requireNotificationTrimmedString(
  Object? raw, {
  required String field,
  required int minLen,
  required int maxLen,
}) {
  if (raw is! String) {
    throw NotificationFailure(
      NotificationFailureCode.invalidInput,
      'Field $field wajib berupa teks.',
    );
  }
  final value = raw.trim();
  if (value.length < minLen || value.length > maxLen) {
    throw NotificationFailure(
      NotificationFailureCode.invalidInput,
      'Panjang $field tidak valid.',
    );
  }
  return value;
}

int parseNotificationNonNegativeInt(String? raw, {required int defaultValue}) {
  if (raw == null || raw.trim().isEmpty) return defaultValue;
  final parsed = int.tryParse(raw.trim());
  if (parsed == null || parsed < 0) {
    throw const NotificationFailure(
      NotificationFailureCode.invalidInput,
      'Parameter numerik tidak valid.',
    );
  }
  return parsed;
}

int parseNotificationBoundedInt(
  String? raw, {
  required int defaultValue,
  required int min,
  required int max,
}) {
  if (raw == null || raw.trim().isEmpty) return defaultValue;
  final parsed = int.tryParse(raw.trim());
  if (parsed == null) {
    throw const NotificationFailure(
      NotificationFailureCode.invalidInput,
      'Parameter batas tidak valid.',
    );
  }
  if (parsed < min) return min;
  if (parsed > max) return max;
  return parsed;
}

import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/errors/owner_errors.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';
import 'package:shelf/shelf.dart';

final _timePattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

String requireOwnerUuid(String raw) {
  final value = tryNormalizeUuid(raw);
  if (value == null) {
    throw const OwnerFailure(OwnerFailureCode.invalidInput);
  }
  return value;
}

Future<Map<String, Object?>> readOwnerJsonBody(Request request) =>
    readJsonObjectBody(
      request,
      onUnsupportedMediaType: () => const OwnerFailure(
        OwnerFailureCode.unsupportedMediaType,
        'Gunakan Content-Type application/json.',
      ),
      onTooLarge: () => const OwnerFailure(OwnerFailureCode.imageTooLarge),
      onInvalidJson: () => const OwnerFailure(OwnerFailureCode.invalidInput),
    );

Future<Uint8List> readOwnerBytes(Request request, {required int limit}) =>
    readRequestBytesLimited(
      request,
      limit: limit,
      onTooLarge: () => const OwnerFailure(OwnerFailureCode.imageTooLarge),
    );

String readRequiredText(
  Map<String, Object?> body,
  String field, {
  required int maxLength,
}) {
  final value = body[field];
  if (value is! String) {
    throw const OwnerFailure(OwnerFailureCode.invalidInput);
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.runes.length > maxLength ||
      hasStrictControlChars(trimmed)) {
    throw const OwnerFailure(OwnerFailureCode.invalidInput);
  }
  return trimmed;
}

String readOptionalText(
  Map<String, Object?> body,
  String field, {
  required int maxLength,
}) {
  final value = body[field];
  if (value == null) return '';
  if (value is! String) {
    throw const OwnerFailure(OwnerFailureCode.invalidInput);
  }
  final trimmed = value.trim();
  if (trimmed.runes.length > maxLength ||
      hasMultilineUnsafeControlChars(trimmed)) {
    throw const OwnerFailure(OwnerFailureCode.invalidInput);
  }
  return trimmed;
}

int readIntField(
  Map<String, Object?> body,
  String field, {
  required int min,
  required int max,
  int? defaultValue,
}) {
  final value = body[field];
  if (value == null && defaultValue != null) return defaultValue;
  if (value is! int || value < min || value > max) {
    throw const OwnerFailure(OwnerFailureCode.invalidInput);
  }
  return value;
}

bool readBoolField(
  Map<String, Object?> body,
  String field, {
  bool? defaultValue,
}) {
  final value = body[field];
  if (value == null && defaultValue != null) return defaultValue;
  if (value is! bool) {
    throw const OwnerFailure(OwnerFailureCode.invalidInput);
  }
  return value;
}

String readRequiredReason(Map<String, Object?> body) {
  final value = body['reason'];
  if (value is! String) {
    throw const OwnerFailure(OwnerFailureCode.reasonRequired);
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw const OwnerFailure(OwnerFailureCode.reasonRequired);
  }
  if (trimmed.runes.length > 500 || hasMultilineUnsafeControlChars(trimmed)) {
    throw const OwnerFailure(OwnerFailureCode.invalidInput);
  }
  return trimmed;
}

List<OwnerScheduleInput> readSchedulesBody(Map<String, Object?> body) {
  final raw = body['schedules'];
  if (raw is! List || raw.length != 7) {
    throw const OwnerFailure(OwnerFailureCode.invalidSchedule);
  }
  final seenDays = <int>{};
  final parsed = <OwnerScheduleInput>[];
  for (final item in raw) {
    if (item is! Map) {
      throw const OwnerFailure(OwnerFailureCode.invalidSchedule);
    }
    final day = item['day_of_week'];
    final isOpenDay = item['is_open_day'];
    if (day is! int ||
        day < 1 ||
        day > 7 ||
        !seenDays.add(day) ||
        isOpenDay is! bool) {
      throw const OwnerFailure(OwnerFailureCode.invalidSchedule);
    }
    if (!isOpenDay) {
      parsed.add((
        dayOfWeek: day,
        isOpenDay: false,
        openTime: null,
        closeTime: null,
      ));
      continue;
    }
    final open = item['open_time'];
    final close = item['close_time'];
    if (open is! String ||
        close is! String ||
        !_timePattern.hasMatch(open) ||
        !_timePattern.hasMatch(close) ||
        open.compareTo(close) >= 0) {
      throw const OwnerFailure(OwnerFailureCode.invalidSchedule);
    }
    parsed.add((
      dayOfWeek: day,
      isOpenDay: true,
      openTime: open,
      closeTime: close,
    ));
  }
  parsed.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
  return parsed;
}

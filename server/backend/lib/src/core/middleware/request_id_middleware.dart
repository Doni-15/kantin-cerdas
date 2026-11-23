import 'dart:math';

import 'package:shelf/shelf.dart';

const requestIdHeader = 'x-request-id';
const requestIdContextKey = 'request_id';

final RegExp _validRequestIdPattern = RegExp(r'^[A-Za-z0-9._-]{1,128}$');
final Random _random = Random.secure();
var _sequenceCounter = 0;

String? normalizeRequestId(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty || !_validRequestIdPattern.hasMatch(trimmed)) {
    return null;
  }
  return trimmed;
}

String generateRequestId() {
  _sequenceCounter = (_sequenceCounter + 1) & 0xffff;
  final timestampHex = DateTime.now()
      .toUtc()
      .microsecondsSinceEpoch
      .toRadixString(16);
  final counterHex = _sequenceCounter.toRadixString(16).padLeft(4, '0');
  final randomHex = _random
      .nextInt(0x100000000)
      .toRadixString(16)
      .padLeft(8, '0');
  return 'req-$timestampHex-$counterHex-$randomHex';
}

String? requestIdFromContext(Request request) {
  final fromContext = request.context[requestIdContextKey];
  if (fromContext is String) {
    final normalized = normalizeRequestId(fromContext);
    if (normalized != null) return normalized;
  }
  return normalizeRequestId(request.headers[requestIdHeader]);
}

Middleware requestIdMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final requestId =
          normalizeRequestId(request.headers[requestIdHeader]) ??
          generateRequestId();
      final correlatedRequest = request.change(
        context: {requestIdContextKey: requestId},
      );
      final response = await innerHandler(correlatedRequest);
      if (response.headers[requestIdHeader] == requestId) {
        return response;
      }
      return response.change(headers: {requestIdHeader: requestId});
    };
  };
}

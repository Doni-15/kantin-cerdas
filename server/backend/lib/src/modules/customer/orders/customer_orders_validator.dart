import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';

typedef ValidatedListQuery = ({
  bool history,
  int limit,
  DateTime? cursorTs,
  String? cursorId,
});

typedef ValidatedCancelInput = ({String mutationId, int expectedVersion});

final class CustomerOrdersValidator {
  const CustomerOrdersValidator._();

  static final RegExp _orderIdPattern = RegExp(r'^ord_[a-f0-9]{32}$');
  static final RegExp _iso8601WithTimezonePattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$',
  );

  static ValidatedListQuery validateListQuery(Map<String, String> query) {
    final rawHistory = query['history']?.trim().toLowerCase();
    final bool history;
    if (rawHistory == 'true') {
      history = true;
    } else if (rawHistory == 'false') {
      history = false;
    } else {
      throw ApiException.unprocessable(
        'Parameter history wajib bernilai true atau false.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'history': 'Gunakan true atau false.'},
      );
    }

    final rawLimit = query['limit']?.trim();
    var limit = 30;
    if (rawLimit != null) {
      final parsedLimit = int.tryParse(rawLimit);
      if (parsedLimit == null || parsedLimit < 1 || parsedLimit > 50) {
        throw ApiException.unprocessable(
          'Parameter limit harus berupa integer antara 1 dan 50.',
          code: 'INVALID_INPUT',
          fieldErrors: const {'limit': 'Gunakan integer antara 1 dan 50.'},
        );
      }
      limit = parsedLimit;
    }

    final rawCursorTs = query['cursorTs']?.trim();
    final rawCursorId = query['cursorId']?.trim();
    DateTime? cursorTs;
    String? cursorId;

    if (rawCursorTs != null && rawCursorTs.isNotEmpty) {
      if (!_iso8601WithTimezonePattern.hasMatch(rawCursorTs) ||
          DateTime.tryParse(rawCursorTs) == null) {
        throw ApiException.unprocessable(
          'Parameter cursorTs harus berupa waktu ISO-8601 dengan zona waktu.',
          code: 'INVALID_INPUT',
          fieldErrors: const {
            'cursorTs':
                'Gunakan format ISO-8601, misalnya 2026-11-12T10:30:00Z.',
          },
        );
      }
      cursorTs = DateTime.parse(rawCursorTs).toUtc();
    }

    if (rawCursorId != null && rawCursorId.isNotEmpty) {
      if (!_orderIdPattern.hasMatch(rawCursorId)) {
        throw ApiException.unprocessable(
          'Parameter cursorId tidak memiliki format ID pesanan yang valid.',
          code: 'INVALID_INPUT',
          fieldErrors: const {
            'cursorId':
                'Gunakan format ord_ diikuti 32 karakter hex huruf kecil.',
          },
        );
      }
      cursorId = rawCursorId;
    }

    if ((cursorTs == null) != (cursorId == null)) {
      throw ApiException.unprocessable(
        'Parameter cursorTs dan cursorId harus diberikan bersama.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'cursorTs': 'Wajib diberikan bersama cursorId.',
          'cursorId': 'Wajib diberikan bersama cursorTs.',
        },
      );
    }

    return (
      history: history,
      limit: limit,
      cursorTs: cursorTs,
      cursorId: cursorId,
    );
  }

  static String validateOrderId(String id) {
    final normalizedId = id.trim();
    if (!_orderIdPattern.hasMatch(normalizedId)) {
      throw ApiException.unprocessable(
        'Format orderId tidak valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'orderId': 'Gunakan format ord_ diikuti 32 karakter hex huruf kecil.',
        },
      );
    }
    return normalizedId;
  }

  static ValidatedCancelInput validateCancelBody(
    Map<String, dynamic> body, {
    String? idempotencyKeyHeader,
  }) {
    final rawHeader = idempotencyKeyHeader?.trim();
    final rawBodyMutationId =
        (body['mutation_id'] is String ? body['mutation_id'] as String : '')
            .trim();

    if (body.containsKey('mutation_id') && body['mutation_id'] is! String) {
      throw ApiException.unprocessable(
        'Field mutation_id harus berupa teks.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'mutation_id': 'Harus berupa teks.'},
      );
    }

    final headerMutationId = rawHeader == null || rawHeader.isEmpty
        ? null
        : rawHeader;
    final bodyMutationId = rawBodyMutationId.isEmpty ? null : rawBodyMutationId;

    if (headerMutationId != null &&
        bodyMutationId != null &&
        headerMutationId != bodyMutationId) {
      throw ApiException.unprocessable(
        'Header Idempotency-Key dan field mutation_id harus sama.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'mutation_id': 'Harus sama dengan Idempotency-Key.',
        },
      );
    }

    final mutationId = headerMutationId ?? bodyMutationId;
    if (mutationId == null ||
        !SecurityConstants.idempotencyKeyPattern.hasMatch(mutationId)) {
      throw ApiException.unprocessable(
        'Idempotency-Key atau mutation_id wajib berupa 48 karakter hex huruf kecil.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'mutation_id': 'Wajib berupa 48 karakter hex huruf kecil.',
        },
      );
    }

    final rawVersion = body['expected_version'];
    if (rawVersion is! int || rawVersion < 1) {
      throw ApiException.unprocessable(
        'Field expected_version wajib berupa integer positif.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'expected_version': 'Gunakan integer lebih besar dari 0.',
        },
      );
    }

    return (mutationId: mutationId, expectedVersion: rawVersion);
  }
}

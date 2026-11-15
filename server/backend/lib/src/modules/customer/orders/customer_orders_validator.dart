import 'package:characters/characters.dart';

import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';

typedef ValidatedListQuery = ({
  bool history,
  int limit,
  DateTime? cursorTs,
  String? cursorId,
});

typedef ValidatedCancelInput = ({String mutationId, int expectedVersion});

typedef ValidatedOrderItemInput = ({
  String menuId,
  int quantity,
  int unitPriceIdr,
  String note,
});

typedef ValidatedCreateOrderInput = ({
  String submissionId,
  String stallId,
  String orderNote,
  int totalPriceIdr,
  List<ValidatedOrderItemInput> items,
});

final class CustomerOrdersValidator {
  const CustomerOrdersValidator._();

  static const int _maxNoteGraphemes = 300;
  static const int _maxNoteCodePoints = 1200;
  static const int _maxOrderTotalIdr = 1000000000;
  static const int _maxMenuPriceIdr = 10000000;
  static const int _maxItemsPerOrder = 100;

  static final RegExp _orderIdPattern = RegExp(r'^ord_[a-f0-9]{32}$');
  static final RegExp _stallIdPattern = RegExp(r'^stl_[a-f0-9]{32}$');
  static final RegExp _menuIdPattern = RegExp(r'^mnu_[a-f0-9]{32}$');
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

  static ValidatedCreateOrderInput validateCreateBody(
    Map<String, dynamic> body, {
    String? idempotencyKeyHeader,
  }) {
    final submissionId = _resolveIdempotencyKey(
      headerValue: idempotencyKeyHeader,
      body: body,
      bodyFieldName: 'submission_id',
    );

    final rawStallId = body['stall_id'];
    if (rawStallId is! String || !_stallIdPattern.hasMatch(rawStallId.trim())) {
      throw ApiException.unprocessable(
        'Field stall_id tidak valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'stall_id':
              'Gunakan format stl_ diikuti 32 karakter hex huruf kecil.',
        },
      );
    }
    final stallId = rawStallId.trim();

    final rawOrderNote = body['order_note'];
    if (rawOrderNote != null && rawOrderNote is! String) {
      throw ApiException.unprocessable(
        'Field order_note harus berupa teks.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'order_note': 'Harus berupa teks.'},
      );
    }
    final orderNote = (rawOrderNote is String ? rawOrderNote : '').trim();
    if (orderNote.characters.length > _maxNoteGraphemes ||
        orderNote.length > _maxNoteCodePoints) {
      throw ApiException.unprocessable(
        'Catatan pesanan maksimal 300 karakter.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'order_note': 'Catatan pesanan maksimal 300 karakter.',
        },
      );
    }

    final rawPaymentMethod = body['payment_method'];
    if (rawPaymentMethod != null &&
        (rawPaymentMethod is! String ||
            rawPaymentMethod.trim() != 'CASH_ON_PICKUP')) {
      throw ApiException.unprocessable(
        'Metode pembayaran hanya mendukung CASH_ON_PICKUP.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'payment_method': 'Gunakan metode pembayaran CASH_ON_PICKUP.',
        },
      );
    }

    final rawTotal = body['total_price_idr'];
    if (rawTotal is! int || rawTotal < 1 || rawTotal > _maxOrderTotalIdr) {
      throw ApiException.unprocessable(
        'Field total_price_idr wajib berupa integer positif yang valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {
          'total_price_idr': 'Harus bernilai antara 1 dan 1000000000.',
        },
      );
    }

    final rawItems = body['items'];
    if (rawItems is! List<Object?> ||
        rawItems.isEmpty ||
        rawItems.length > _maxItemsPerOrder) {
      throw ApiException.unprocessable(
        'Daftar item pesanan wajib berisi 1 hingga $_maxItemsPerOrder item.',
        code: 'INVALID_ORDER_ITEMS',
        fieldErrors: const {
          'items': 'Isi minimal 1 dan maksimal 100 item pesanan.',
        },
      );
    }

    final items = <ValidatedOrderItemInput>[];
    final seenMenuIds = <String>{};

    for (var i = 0; i < rawItems.length; i++) {
      final rawItem = rawItems[i];
      if (rawItem is! Map<Object?, Object?>) {
        throw ApiException.unprocessable(
          'Setiap item pesanan harus berupa objek JSON.',
          code: 'INVALID_ORDER_ITEMS',
          fieldErrors: {'items[$i]': 'Format item tidak valid.'},
        );
      }

      final rawMenuId = rawItem['menu_id'];
      if (rawMenuId is! String || !_menuIdPattern.hasMatch(rawMenuId.trim())) {
        throw ApiException.unprocessable(
          'Identitas menu pada item pesanan tidak valid.',
          code: 'INVALID_ORDER_ITEMS',
          fieldErrors: {'items[$i].menu_id': 'Format menu_id tidak valid.'},
        );
      }
      final menuId = rawMenuId.trim();
      if (!seenMenuIds.add(menuId)) {
        throw ApiException.unprocessable(
          'Terdapat menu_id duplikat di dalam daftar item pesanan.',
          code: 'INVALID_ORDER_ITEMS',
          fieldErrors: {
            'items[$i].menu_id':
                'Gabungkan kuantitas untuk menu yang sama menjadi satu baris.',
          },
        );
      }

      final rawQty = rawItem['quantity'];
      if (rawQty is! int || rawQty < 1 || rawQty > 99) {
        throw ApiException.unprocessable(
          'Kuantitas item wajib bernilai antara 1 dan 99.',
          code: 'INVALID_QUANTITY',
          fieldErrors: {
            'items[$i].quantity': 'Gunakan bilangan bulat 1..99.',
          },
        );
      }

      final rawUnitPrice = rawItem['unit_price_idr'];
      if (rawUnitPrice is! int ||
          rawUnitPrice < 1 ||
          rawUnitPrice > _maxMenuPriceIdr) {
        throw ApiException.unprocessable(
          'Harga satuan konfirmasi item tidak valid.',
          code: 'INVALID_ORDER_ITEMS',
          fieldErrors: {
            'items[$i].unit_price_idr': 'Harga satuan tidak valid.',
          },
        );
      }

      final rawItemNote = rawItem['note'];
      if (rawItemNote != null && rawItemNote is! String) {
        throw ApiException.unprocessable(
          'Catatan item harus berupa teks.',
          code: 'INVALID_INPUT',
          fieldErrors: {'items[$i].note': 'Harus berupa teks.'},
        );
      }
      final itemNote = (rawItemNote is String ? rawItemNote : '').trim();
      if (itemNote.characters.length > _maxNoteGraphemes ||
          itemNote.length > _maxNoteCodePoints) {
        throw ApiException.unprocessable(
          'Catatan item maksimal 300 karakter.',
          code: 'INVALID_INPUT',
          fieldErrors: {
            'items[$i].note': 'Catatan item maksimal 300 karakter.',
          },
        );
      }

      items.add((
        menuId: menuId,
        quantity: rawQty,
        unitPriceIdr: rawUnitPrice,
        note: itemNote,
      ));
    }

    return (
      submissionId: submissionId,
      stallId: stallId,
      orderNote: orderNote,
      totalPriceIdr: rawTotal,
      items: items,
    );
  }

  static ValidatedCancelInput validateCancelBody(
    Map<String, dynamic> body, {
    String? idempotencyKeyHeader,
  }) {
    final mutationId = _resolveIdempotencyKey(
      headerValue: idempotencyKeyHeader,
      body: body,
      bodyFieldName: 'mutation_id',
    );

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

  static String _resolveIdempotencyKey({
    required String? headerValue,
    required Map<String, dynamic> body,
    required String bodyFieldName,
  }) {
    final rawHeader = headerValue?.trim();
    final rawBodyValue = body[bodyFieldName];
    if (body.containsKey(bodyFieldName) && rawBodyValue is! String) {
      throw ApiException.unprocessable(
        'Field $bodyFieldName harus berupa teks.',
        code: 'INVALID_INPUT',
        fieldErrors: {bodyFieldName: 'Harus berupa teks.'},
      );
    }

    final headerKey =
        rawHeader == null || rawHeader.isEmpty ? null : rawHeader;
    final bodyKeyStr = (rawBodyValue is String ? rawBodyValue : '').trim();
    final bodyKey = bodyKeyStr.isEmpty ? null : bodyKeyStr;

    if (headerKey != null && bodyKey != null && headerKey != bodyKey) {
      throw ApiException.unprocessable(
        'Header Idempotency-Key dan field $bodyFieldName harus sama.',
        code: 'INVALID_INPUT',
        fieldErrors: {
          bodyFieldName: 'Harus sama dengan Idempotency-Key.',
        },
      );
    }

    final resolved = headerKey ?? bodyKey;
    if (resolved == null ||
        !SecurityConstants.idempotencyKeyPattern.hasMatch(resolved)) {
      throw ApiException.unprocessable(
        'Idempotency-Key atau $bodyFieldName wajib berupa 48 karakter hex huruf kecil.',
        code: 'INVALID_INPUT',
        fieldErrors: {
          bodyFieldName: 'Wajib berupa 48 karakter hex huruf kecil.',
        },
      );
    }
    return resolved;
  }
}

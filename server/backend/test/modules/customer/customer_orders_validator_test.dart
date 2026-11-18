import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_validator.dart';
import 'package:test/test.dart';

const _validSubmissionId = '0123456789abcdef0123456789abcdef0123456789abcdef';
const _validStallId = 'stl_0123456789abcdef0123456789abcdef';
const _validMenuId = 'mnu_0123456789abcdef0123456789abcdef';

Map<String, dynamic> _validOrderBody() => <String, dynamic>{
  'submission_id': _validSubmissionId,
  'stall_id': _validStallId,
  'order_note': 'Catatan pesanan',
  'payment_method': 'CASH_ON_PICKUP',
  'total_price_idr': 15000,
  'items': <Object?>[_validOrderItem()],
};

Map<String, Object?> _validOrderItem({
  String menuId = _validMenuId,
  int quantity = 1,
  int unitPriceIdr = 15000,
  Object? note = '',
}) => <String, Object?>{
  'menu_id': menuId,
  'quantity': quantity,
  'unit_price_idr': unitPriceIdr,
  'note': note,
};

Matcher _unprocessableWithCode(String code) => isA<ApiException>()
    .having((error) => error.statusCode, 'statusCode', 422)
    .having((error) => error.code, 'code', code);

String _repeated(String value, int count) =>
    List<String>.filled(count, value).join();

void main() {
  group('CustomerOrdersValidator.validateCreateBody', () {
    test('menerima payload pembuatan pesanan yang valid', () {
      final input = CustomerOrdersValidator.validateCreateBody(
        <String, dynamic>{
          ..._validOrderBody(),
          'order_note': '  Jangan terlalu pedas  ',
          'total_price_idr': 35000,
          'items': <Object?>[
            _validOrderItem(
              quantity: 2,
              unitPriceIdr: 15000,
              note: ' Tanpa bawang ',
            ),
            _validOrderItem(
              menuId: 'mnu_abcdef0123456789abcdef0123456789',
              unitPriceIdr: 5000,
            ),
          ],
        },
        idempotencyKeyHeader: _validSubmissionId,
      );

      expect(input.submissionId, _validSubmissionId);
      expect(input.stallId, _validStallId);
      expect(input.orderNote, 'Jangan terlalu pedas');
      expect(input.totalPriceIdr, 35000);
      expect(input.items, hasLength(2));
      expect(input.items.first.menuId, _validMenuId);
      expect(input.items.first.quantity, 2);
      expect(input.items.first.unitPriceIdr, 15000);
      expect(input.items.first.note, 'Tanpa bawang');
    });

    for (final fieldAndCode in <(String, String)>[
      ('stall_id', 'INVALID_INPUT'),
      ('items', 'INVALID_ORDER_ITEMS'),
      ('total_price_idr', 'INVALID_INPUT'),
      ('payment_method', 'INVALID_INPUT'),
    ]) {
      final (field, code) = fieldAndCode;
      test('menolak jika field wajib $field tidak diberikan', () {
        final body = _validOrderBody()..remove(field);

        expect(
          () => CustomerOrdersValidator.validateCreateBody(
            body,
            idempotencyKeyHeader: _validSubmissionId,
          ),
          throwsA(_unprocessableWithCode(code)),
        );
      });
    }

    test('mewajibkan metode pembayaran CASH_ON_PICKUP', () {
      final body = _validOrderBody()..['payment_method'] = 'CARD';

      expect(
        () => CustomerOrdersValidator.validateCreateBody(
          body,
          idempotencyKeyHeader: _validSubmissionId,
        ),
        throwsA(_unprocessableWithCode('INVALID_INPUT')),
      );
    });

    test('menerima jumlah item pada batas 1 dan 100', () {
      final singleItemInput = CustomerOrdersValidator.validateCreateBody(
        _validOrderBody(),
        idempotencyKeyHeader: _validSubmissionId,
      );
      expect(singleItemInput.items, hasLength(1));

      final hundredItemsBody = _validOrderBody()
        ..['items'] = <Object?>[
          for (var index = 0; index < 100; index++)
            _validOrderItem(
              menuId: 'mnu_${index.toRadixString(16).padLeft(32, '0')}',
            ),
        ];
      final hundredItemsInput = CustomerOrdersValidator.validateCreateBody(
        hundredItemsBody,
        idempotencyKeyHeader: _validSubmissionId,
      );
      expect(hundredItemsInput.items, hasLength(100));
    });

    test('menolak daftar item kosong atau lebih dari 100 item', () {
      for (final items in <List<Object?>>[
        <Object?>[],
        <Object?>[
          for (var index = 0; index < 101; index++)
            _validOrderItem(
              menuId: 'mnu_${index.toRadixString(16).padLeft(32, '0')}',
            ),
        ],
      ]) {
        final body = _validOrderBody()..['items'] = items;

        expect(
          () => CustomerOrdersValidator.validateCreateBody(
            body,
            idempotencyKeyHeader: _validSubmissionId,
          ),
          throwsA(_unprocessableWithCode('INVALID_ORDER_ITEMS')),
        );
      }
    });

    test('menerima kuantitas pada batas 1 dan 99', () {
      for (final quantity in <int>[1, 99]) {
        final body = _validOrderBody()
          ..['items'] = <Object?>[_validOrderItem(quantity: quantity)];

        final input = CustomerOrdersValidator.validateCreateBody(
          body,
          idempotencyKeyHeader: _validSubmissionId,
        );

        expect(input.items.single.quantity, quantity);
      }
    });

    test('menolak kuantitas di luar rentang 1..99', () {
      for (final quantity in <int>[0, 100]) {
        final body = _validOrderBody()
          ..['items'] = <Object?>[_validOrderItem(quantity: quantity)];

        expect(
          () => CustomerOrdersValidator.validateCreateBody(
            body,
            idempotencyKeyHeader: _validSubmissionId,
          ),
          throwsA(_unprocessableWithCode('INVALID_QUANTITY')),
        );
      }
    });

    test('menerima catatan maksimal 300 grapheme dan menolak 301', () {
      final threeHundredGraphemes = List<String>.filled(300, 'e\u0301').join();
      final acceptedBody = _validOrderBody()
        ..['order_note'] = threeHundredGraphemes;
      final input = CustomerOrdersValidator.validateCreateBody(
        acceptedBody,
        idempotencyKeyHeader: _validSubmissionId,
      );
      expect(input.orderNote, threeHundredGraphemes);

      final threeHundredOneGraphemes = List<String>.filled(
        301,
        'e\u0301',
      ).join();
      final rejectedBody = _validOrderBody()
        ..['items'] = <Object?>[
          _validOrderItem(note: threeHundredOneGraphemes),
        ];

      expect(
        () => CustomerOrdersValidator.validateCreateBody(
          rejectedBody,
          idempotencyKeyHeader: _validSubmissionId,
        ),
        throwsA(_unprocessableWithCode('INVALID_INPUT')),
      );
    });

    test('menolak menu_id duplikat di dalam items', () {
      final body = _validOrderBody()
        ..['items'] = <Object?>[_validOrderItem(), _validOrderItem()];

      expect(
        () => CustomerOrdersValidator.validateCreateBody(
          body,
          idempotencyKeyHeader: _validSubmissionId,
        ),
        throwsA(_unprocessableWithCode('INVALID_ORDER_ITEMS')),
      );
    });

    test('mewajibkan Idempotency-Key atau submission_id', () {
      final body = _validOrderBody()..remove('submission_id');

      expect(
        () => CustomerOrdersValidator.validateCreateBody(body),
        throwsA(_unprocessableWithCode('INVALID_INPUT')),
      );
    });

    test('menerima Idempotency-Key berupa 48 karakter hex huruf kecil', () {
      final body = _validOrderBody()..remove('submission_id');
      final input = CustomerOrdersValidator.validateCreateBody(
        body,
        idempotencyKeyHeader: _validSubmissionId,
      );

      expect(input.submissionId, _validSubmissionId);
    });

    test('menolak Idempotency-Key yang bukan 48 karakter hex huruf kecil', () {
      final body = _validOrderBody()..remove('submission_id');
      final invalidKeys = <String>[
        _repeated('a', 47),
        _repeated('a', 49),
        _repeated('A', 48),
        '${_repeated('a', 47)}g',
      ];

      for (final key in invalidKeys) {
        expect(
          () => CustomerOrdersValidator.validateCreateBody(
            body,
            idempotencyKeyHeader: key,
          ),
          throwsA(_unprocessableWithCode('INVALID_INPUT')),
        );
      }
    });

    test('menolak header Idempotency-Key dan submission_id yang berbeda', () {
      expect(
        () => CustomerOrdersValidator.validateCreateBody(
          _validOrderBody(),
          idempotencyKeyHeader:
              'abcdef0123456789abcdef0123456789abcdef0123456789',
        ),
        throwsA(_unprocessableWithCode('INVALID_INPUT')),
      );
    });
  });
}

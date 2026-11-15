import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_validator.dart';
import 'package:test/test.dart';

void main() {
  const validSubmissionId = '0123456789abcdef0123456789abcdef0123456789abcdef';
  const validStallId = 'stl_0123456789abcdef0123456789abcdef';
  const validMenuId1 = 'mnu_0123456789abcdef0123456789abcdef';
  const validMenuId2 = 'mnu_abcdef0123456789abcdef0123456789';

  group('CustomerOrdersValidator.validateCreateBody', () {
    test('menerima payload pembuatan pesanan yang valid', () {
      final input = CustomerOrdersValidator.validateCreateBody(
        <String, dynamic>{
          'submission_id': validSubmissionId,
          'stall_id': validStallId,
          'order_note': '  Jangan terlalu pedas  ',
          'payment_method': 'CASH_ON_PICKUP',
          'total_price_idr': 35000,
          'items': <Object?>[
            <String, Object?>{
              'menu_id': validMenuId1,
              'quantity': 2,
              'unit_price_idr': 15000,
              'note': ' Tanpa bawang ',
            },
            <String, Object?>{
              'menu_id': validMenuId2,
              'quantity': 1,
              'unit_price_idr': 5000,
              'note': '',
            },
          ],
        },
        idempotencyKeyHeader: validSubmissionId,
      );

      expect(input.submissionId, validSubmissionId);
      expect(input.stallId, validStallId);
      expect(input.orderNote, 'Jangan terlalu pedas');
      expect(input.totalPriceIdr, 35000);
      expect(input.items.length, 2);
      expect(input.items.first.menuId, validMenuId1);
      expect(input.items.first.quantity, 2);
      expect(input.items.first.unitPriceIdr, 15000);
      expect(input.items.first.note, 'Tanpa bawang');
    });

    test('menolak jika terdapat menu_id duplikat di dalam items', () {
      expect(
        () => CustomerOrdersValidator.validateCreateBody(
          <String, dynamic>{
            'submission_id': validSubmissionId,
            'stall_id': validStallId,
            'total_price_idr': 30000,
            'items': <Object?>[
              <String, Object?>{
                'menu_id': validMenuId1,
                'quantity': 1,
                'unit_price_idr': 15000,
              },
              <String, Object?>{
                'menu_id': validMenuId1,
                'quantity': 1,
                'unit_price_idr': 15000,
              },
            ],
          },
          idempotencyKeyHeader: validSubmissionId,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.code, 'code', 'INVALID_ORDER_ITEMS'),
        ),
      );
    });

    test('menolak jika kuantitas item di luar rentang 1..99', () {
      expect(
        () => CustomerOrdersValidator.validateCreateBody(
          <String, dynamic>{
            'submission_id': validSubmissionId,
            'stall_id': validStallId,
            'total_price_idr': 15000,
            'items': <Object?>[
              <String, Object?>{
                'menu_id': validMenuId1,
                'quantity': 0,
                'unit_price_idr': 15000,
              },
            ],
          },
          idempotencyKeyHeader: validSubmissionId,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.code, 'code', 'INVALID_QUANTITY'),
        ),
      );
    });
  });
}

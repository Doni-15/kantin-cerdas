import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/domain/validation/order_record_rules.dart';

/// Pesanan valid bawaan: 2 x 15.000 + 1 x 10.000 = 40.000, status `waiting`.
OrderRecord buildOrder({
  OrderStatus status = OrderStatus.waiting,
  OrderPaymentStatus paymentStatus = OrderPaymentStatus.unpaid,
  List<OrderLine>? items,
  int? totalPriceIdr,
  String? rejectionReason,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 1, 1, 10);
  return OrderRecord(
    id: 'ord-1',
    orderNumber: 'KC-0001',
    customerId: 'usr-1',
    customerName: 'Doni',
    stallId: 'stall-1',
    stallName: 'Kantin A',
    items:
        items ??
        [
          OrderLine(
            menuId: 'menu-1',
            name: 'Nasi Goreng',
            quantity: 2,
            unitPriceIdr: 15000,
            note: '',
          ),
          OrderLine(
            menuId: 'menu-2',
            name: 'Es Teh',
            quantity: 1,
            unitPriceIdr: 10000,
            note: '',
          ),
        ],
    status: status,
    paymentStatus: paymentStatus,
    totalPriceIdr: totalPriceIdr ?? 40000,
    note: '',
    createdAt: created,
    updatedAt: updatedAt ?? created,
    version: 1,
    rejectionReason: rejectionReason,
  );
}

/// Aturan ini menolak snapshot pesanan yang tidak masuk akal dari server
/// (misalnya pesanan selesai tetapi belum lunas, atau total tidak sama dengan
/// jumlah subtotal). Kesalahan di sini berarti salah catat uang atau status.
void main() {
  group('OrderRecordRules.hasConsistentPayment', () {
    test('status pesanan menentukan satu-satunya status bayar yang sah', () {
      const expectedPayment = <OrderStatus, OrderPaymentStatus>{
        OrderStatus.waiting: OrderPaymentStatus.unpaid,
        OrderStatus.processing: OrderPaymentStatus.unpaid,
        OrderStatus.ready: OrderPaymentStatus.unpaid,
        OrderStatus.completed: OrderPaymentStatus.paid,
        OrderStatus.rejected: OrderPaymentStatus.notCharged,
        OrderStatus.cancelled: OrderPaymentStatus.notCharged,
      };

      expect(expectedPayment.keys, unorderedEquals(OrderStatus.values));

      for (final entry in expectedPayment.entries) {
        for (final payment in OrderPaymentStatus.values) {
          final order = buildOrder(
            status: entry.key,
            paymentStatus: payment,
            rejectionReason: entry.key == OrderStatus.rejected
                ? 'Stok habis'
                : null,
          );
          expect(
            OrderRecordRules.hasConsistentPayment(order),
            payment == entry.value,
            reason: '${entry.key.name} dengan pembayaran ${payment.name}',
          );
        }
      }
    });
  });

  group('OrderRecordRules.hasConsistentSnapshot', () {
    test('pesanan yang utuh dinyatakan konsisten', () {
      expect(OrderRecordRules.hasConsistentSnapshot(buildOrder()), isTrue);
    });

    test('total harus sama persis dengan jumlah subtotal item', () {
      expect(
        OrderRecordRules.hasConsistentSnapshot(
          buildOrder(totalPriceIdr: 39999),
        ),
        isFalse,
      );
      expect(
        OrderRecordRules.hasConsistentSnapshot(
          buildOrder(totalPriceIdr: 40001),
        ),
        isFalse,
      );
    });

    test('menu yang sama tidak boleh muncul dua kali dalam satu pesanan', () {
      final duplicated = [
        OrderLine(
          menuId: 'menu-1',
          name: 'Nasi Goreng',
          quantity: 1,
          unitPriceIdr: 15000,
          note: '',
        ),
        OrderLine(
          menuId: 'menu-1',
          name: 'Nasi Goreng',
          quantity: 1,
          unitPriceIdr: 15000,
          note: '',
        ),
      ];

      expect(
        OrderRecordRules.hasConsistentSnapshot(
          buildOrder(items: duplicated, totalPriceIdr: 30000),
        ),
        isFalse,
      );
    });

    test('waktu pembaruan tidak boleh mendahului waktu pembuatan', () {
      final created = DateTime.utc(2026, 1, 1, 10);

      expect(
        OrderRecordRules.hasConsistentSnapshot(
          buildOrder(
            createdAt: created,
            updatedAt: created.subtract(const Duration(seconds: 1)),
          ),
        ),
        isFalse,
      );
      expect(
        OrderRecordRules.hasConsistentSnapshot(
          buildOrder(createdAt: created, updatedAt: created),
        ),
        isTrue,
      );
    });

    test('pesanan ditolak wajib punya alasan tidak kosong', () {
      OrderRecord rejected(String? reason) => buildOrder(
        status: OrderStatus.rejected,
        paymentStatus: OrderPaymentStatus.notCharged,
        rejectionReason: reason,
      );

      expect(
        OrderRecordRules.hasConsistentSnapshot(rejected('Stok habis')),
        isTrue,
      );
      expect(OrderRecordRules.hasConsistentSnapshot(rejected(null)), isFalse);
      expect(OrderRecordRules.hasConsistentSnapshot(rejected('   ')), isFalse);
    });

    test(
      'alasan penolakan dibatasi 300 karakter yang tampak, bukan 300 unit',
      () {
        OrderRecord rejected(String reason) => buildOrder(
          status: OrderStatus.rejected,
          paymentStatus: OrderPaymentStatus.notCharged,
          rejectionReason: reason,
        );

        expect(
          OrderRecordRules.hasConsistentSnapshot(rejected('a' * 300)),
          isTrue,
        );
        expect(
          OrderRecordRules.hasConsistentSnapshot(rejected('a' * 301)),
          isFalse,
        );

        // "é" ditulis sebagai e + tanda aksen: 1 karakter tampak, 2 unit kode.
        const accented = 'e\u0301';
        expect(
          OrderRecordRules.hasConsistentSnapshot(rejected(accented * 300)),
          isTrue,
        );
        expect(
          OrderRecordRules.hasConsistentSnapshot(rejected(accented * 301)),
          isFalse,
        );
      },
    );

    test('pesanan yang tidak ditolak tidak boleh membawa alasan penolakan', () {
      expect(
        OrderRecordRules.hasConsistentSnapshot(
          buildOrder(rejectionReason: 'Stok habis'),
        ),
        isFalse,
      );
      expect(
        OrderRecordRules.hasConsistentSnapshot(
          buildOrder(rejectionReason: '   '),
        ),
        isTrue,
      );
    });

    test(
      'status dan pembayaran yang saling bertentangan ikut menggagalkan snapshot',
      () {
        expect(
          OrderRecordRules.hasConsistentSnapshot(
            buildOrder(
              status: OrderStatus.completed,
              paymentStatus: OrderPaymentStatus.unpaid,
            ),
          ),
          isFalse,
        );
      },
    );
  });

  group('OrderStatus.isTerminal', () {
    test('hanya selesai, ditolak, dan dibatalkan yang berstatus akhir', () {
      const terminal = {
        OrderStatus.completed,
        OrderStatus.rejected,
        OrderStatus.cancelled,
      };

      for (final status in OrderStatus.values) {
        expect(
          status.isTerminal,
          terminal.contains(status),
          reason: status.name,
        );
      }
    });
  });
}

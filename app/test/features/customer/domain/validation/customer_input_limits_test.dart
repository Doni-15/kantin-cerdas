import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

/// Batas pelanggan didefinisikan di `CustomerInputLimits`, tetapi entitas
/// `OrderLine` menuliskan angka yang sama sendiri. Test ini menjaga keduanya
/// tidak bergeser: UI yang menerima input yang ditolak entitas akan crash,
/// sedangkan UI yang terlalu ketat menolak pesanan yang sebenarnya sah.
bool lineAccepts({
  int quantity = 1,
  int unitPriceIdr = 1000,
  String note = '',
}) {
  try {
    OrderLine(
      menuId: 'menu-1',
      name: 'Nasi Goreng',
      quantity: quantity,
      unitPriceIdr: unitPriceIdr,
      note: note,
    );
    return true;
  } on ArgumentError {
    return false;
  }
}

void main() {
  group('CustomerInputLimits', () {
    test('batas jumlah porsi 1..99 sama dengan yang diterima OrderLine', () {
      for (final quantity in [-1, 0, 1, 2, 98, 99, 100]) {
        expect(
          CustomerInputLimits.validQuantity(quantity),
          lineAccepts(quantity: quantity),
          reason: 'quantity $quantity',
        );
      }
      expect(CustomerInputLimits.validQuantity(0), isFalse);
      expect(CustomerInputLimits.validQuantity(1), isTrue);
      expect(CustomerInputLimits.validQuantity(99), isTrue);
      expect(CustomerInputLimits.validQuantity(100), isFalse);
    });

    test(
      'batas harga satuan 1..10.000.000 sama dengan yang diterima OrderLine',
      () {
        for (final price in [-1, 0, 1, 9999999, 10000000, 10000001]) {
          expect(
            CustomerInputLimits.validPrice(price),
            lineAccepts(unitPriceIdr: price),
            reason: 'harga $price',
          );
        }
        expect(CustomerInputLimits.validPrice(0), isFalse);
        expect(CustomerInputLimits.validPrice(10000000), isTrue);
        expect(CustomerInputLimits.validPrice(10000001), isFalse);
      },
    );

    test('catatan dibatasi 300 karakter tampak, sama dengan OrderLine', () {
      const accented = 'e\u0301';

      for (final note in [
        '',
        'a' * 300,
        'a' * 301,
        accented * 300,
        accented * 301,
      ]) {
        expect(
          CustomerInputLimits.validNote(note),
          lineAccepts(note: note),
          reason: 'catatan sepanjang ${note.length} unit kode',
        );
      }
      expect(CustomerInputLimits.validNote(accented * 300), isTrue);
      expect(CustomerInputLimits.validNote(accented * 301), isFalse);
    });
  });
}

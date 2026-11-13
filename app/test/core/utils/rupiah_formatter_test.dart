import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';

/// Spasi antara simbol dan angka bisa berupa spasi biasa atau non-breaking
/// space tergantung versi data locale, sehingga dibuang sebelum dibandingkan.
String compact(int amount) =>
    formatRupiah(amount).replaceAll(RegExp(r'\s'), '');

void main() {
  group('formatRupiah', () {
    test('memakai simbol Rp dan titik sebagai pemisah ribuan', () {
      expect(compact(15000), 'Rp15.000');
      expect(compact(1500000), 'Rp1.500.000');
    });

    test('tidak menampilkan desimal', () {
      expect(compact(0), 'Rp0');
      expect(compact(999), 'Rp999');
      expect(formatRupiah(15000), isNot(contains(',')));
    });
  });
}

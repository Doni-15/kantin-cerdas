import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/utils/mutation_id_generator.dart';

void main() {
  group('generateSecureMutationId', () {
    test('menghasilkan ID 48 heksadesimal yang berbeda setiap pemanggilan', () {
      final id1 = generateSecureMutationId();
      final id2 = generateSecureMutationId();
      expect(id1, hasLength(48));
      expect(id1, matches(RegExp(r'^[0-9a-f]{48}$')));
      expect(id1, isNot(equals(id2)));
    });
  });
}

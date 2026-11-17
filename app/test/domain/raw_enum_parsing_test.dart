import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

void main() {
  group('Parsing enum domain dari nilai mentah backend', () {
    test(
      'tryFromRaw menormalisasi spasi, huruf besar, dan alias nilai mentah',
      () {
        expect(UserRole.tryFromRaw(' OWNER '), UserRole.owner);
        expect(UserRole.tryFromRaw('invalid'), isNull);
        expect(OrderStatus.tryFromRaw(' CANCELLED '), OrderStatus.cancelled);
        expect(OrderStatus.tryFromRaw('canceled'), OrderStatus.cancelled);
        expect(OrderStatus.tryFromRaw('unknown'), isNull);
        expect(
          OrderPaymentStatus.tryFromRaw('not_charged'),
          OrderPaymentStatus.notCharged,
        );
        expect(
          CanteenApplicationStatus.tryFromRaw(' REVIEWING '),
          CanteenApplicationStatus.reviewing,
        );
      },
    );
  });
}

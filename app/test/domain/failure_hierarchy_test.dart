import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/presentation/mappers/owner_labels.dart';

void main() {
  group('Hierarki failure sealed', () {
    test(
      'OwnerFailure dan CustomerFeatureFailure mendukung pattern matching sealed class',
      () {
        const OwnerFailure failure = OwnerInvalidDataFailure();
        expect(failure, isA<OwnerInvalidDataFailure>());
        expect(failure, equals(const OwnerInvalidDataFailure()));
        expect(ownerFailureMessage(failure), contains('belum sesuai'));

        const CustomerFeatureFailure custFailure =
            CustomerFeatureReadTimeoutFailure();
        expect(custFailure, isA<CustomerFeatureReadTimeoutFailure>());
        expect(custFailure, equals(const CustomerFeatureReadTimeoutFailure()));
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';

void main() {
  group('AuthValidator: batas panjang maksimum', () {
    test(
      'AuthValidator menolak nama dan password yang melebihi batas karakter maksimum',
      () {
        expect(AuthValidator.name('A' * 120), isNull);
        expect(AuthValidator.name('A' * 121), AuthValidationIssue.tooLong);
        expect(AuthValidator.password('P' * 128), isNull);
        expect(
          AuthValidator.password('P' * 129),
          AuthValidationIssue.passwordTooLong,
        );
      },
    );
  });
}

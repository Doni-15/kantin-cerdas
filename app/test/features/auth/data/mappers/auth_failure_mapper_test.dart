import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/auth_failure_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthFailureMapper (HIGH-01)', () {
    test(
      'memetakan 403 ACCOUNT_DISABLED, 409 USERNAME/EMAIL_TAKEN, 429, dan INVALID_CURRENT_PASSWORD',
      () {
        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 403,
              code: 'ACCOUNT_DISABLED',
            ),
            operation: AuthApiOperation.login,
          ),
          isA<AuthAccountDisabledFailure>(),
        );

        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 409,
              code: 'USERNAME_TAKEN',
            ),
            operation: AuthApiOperation.register,
          ),
          isA<AuthUsernameTakenFailure>(),
        );

        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 409,
              code: 'EMAIL_TAKEN',
            ),
            operation: AuthApiOperation.register,
          ),
          isA<AuthEmailTakenFailure>(),
        );

        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 400,
              code: 'INVALID_CURRENT_PASSWORD',
            ),
            operation: AuthApiOperation.changePassword,
          ),
          isA<AuthInvalidCurrentPasswordFailure>(),
        );

        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 429,
              code: 'RATE_LIMITED',
            ),
            operation: AuthApiOperation.login,
          ),
          isA<AuthRateLimitedFailure>(),
        );
      },
    );
  });
}

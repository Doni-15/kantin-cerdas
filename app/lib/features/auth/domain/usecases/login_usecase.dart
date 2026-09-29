import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';

class LoginUseCase {
  const LoginUseCase(this.repository);

  final AuthRepository repository;

  Future<User> execute({
    required String identifier,
    required String password,
  }) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();

    final errors = <String, String>{};

    final identifierError = AuthValidator.identifier(normalizedIdentifier);
    if (identifierError != null) errors['identifier'] = identifierError;

    final passwordError = AuthValidator.loginPassword(password);
    if (passwordError != null) errors['password'] = passwordError;

    if (errors.isNotEmpty) {
      throw ValidationFailure(errors);
    }

    return repository.login(
      identifier: normalizedIdentifier,
      password: password,
    );
  }
}

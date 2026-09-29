import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this.repository);

  final AuthRepository repository;

  Future<void> execute({
    required String currentPassword,
    required String newPassword,
  }) async {
    final errors = <String, String>{};

    final currentError = AuthValidator.currentPassword(currentPassword);
    if (currentError != null) errors['current_password'] = currentError;

    final newError = AuthValidator.newPassword(currentPassword, newPassword);
    if (newError != null) errors['new_password'] = newError;

    if (errors.isNotEmpty) {
      throw ValidationFailure(errors);
    }

    return repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

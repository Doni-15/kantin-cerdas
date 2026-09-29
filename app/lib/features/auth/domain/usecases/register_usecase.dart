import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';

class RegisterUseCase {
  const RegisterUseCase(this.repository);

  final AuthRepository repository;

  Future<User> execute({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();

    final errors = <String, String>{};

    final nameError = AuthValidator.name(normalizedName);
    if (nameError != null) errors['name'] = nameError;

    final usernameError = AuthValidator.username(normalizedUsername);
    if (usernameError != null) errors['username'] = usernameError;

    final emailError = AuthValidator.email(normalizedEmail);
    if (emailError != null) errors['email'] = emailError;

    final passwordError = AuthValidator.password(password);
    if (passwordError != null) errors['password'] = passwordError;

    if (errors.isNotEmpty) {
      throw ValidationFailure(errors);
    }

    return repository.register(
      name: normalizedName,
      username: normalizedUsername,
      email: normalizedEmail,
      password: password,
    );
  }
}

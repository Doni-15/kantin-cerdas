import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this.repository);
  final AuthRepository repository;

  Future<User> execute({
    required String username,
    required String password,
  }) {
    return repository.login(
      username: username,
      password: password,
    );
  }
}
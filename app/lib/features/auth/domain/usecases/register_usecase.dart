import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this.repository);
  final AuthRepository repository;

  Future<User> execute({
    required String name,
    required String username,
    required String email,
    required String password,
  }) {
    return repository.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );
  }
}
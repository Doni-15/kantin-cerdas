import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this.repository);

  final AuthRepository repository;

  Future<void> execute() {
    return repository.logout();
  }
}

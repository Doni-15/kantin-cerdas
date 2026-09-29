import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this.repository);

  final AuthRepository repository;

  Future<User?> execute() {
    return repository.restoreSession();
  }
}

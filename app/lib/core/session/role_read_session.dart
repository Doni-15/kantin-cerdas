import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/auth_state_provider.dart';
import 'package:kantin_cerdas/core/session/user_role.dart';

/// Snapshot sesi terpusat untuk satu evaluasi provider baca lintas await.
class RoleReadSession {
  RoleReadSession._({
    required this.actorId,
    required this.rolePredicate,
    required this.forbiddenError,
    required this.notifier,
    required this.generation,
  });

  factory RoleReadSession.capture(
    Ref ref, {
    required bool Function(UserRole role) rolePredicate,
    required Exception Function() forbiddenError,
  }) {
    final auth = ref.watch(authStateProvider);
    final notifier = ref.watch(authStateProvider.notifier);
    final user = auth.asData?.value;
    if (auth.isLoading ||
        auth.hasError ||
        user == null ||
        !user.isActive ||
        !rolePredicate(user.role)) {
      throw forbiddenError();
    }
    return RoleReadSession._(
      actorId: user.id,
      rolePredicate: rolePredicate,
      forbiddenError: forbiddenError,
      notifier: notifier,
      generation: notifier.sessionGeneration,
    );
  }

  final String actorId;
  final bool Function(UserRole role) rolePredicate;
  final Exception Function() forbiddenError;
  final AuthStateNotifier notifier;
  final int generation;

  void check(Ref ref) {
    if (!ref.mounted) {
      throw forbiddenError();
    }
    final auth = ref.read(authStateProvider);
    final currentNotifier = ref.read(authStateProvider.notifier);
    final user = auth.asData?.value;
    if (auth.isLoading ||
        auth.hasError ||
        user == null ||
        !user.isActive ||
        !rolePredicate(user.role) ||
        user.id != actorId ||
        !identical(notifier, currentNotifier) ||
        currentNotifier.sessionGeneration != generation) {
      throw forbiddenError();
    }
  }
}

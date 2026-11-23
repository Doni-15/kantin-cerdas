import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/providers/auth_repository_provider.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';

export 'package:kantin_cerdas/features/auth/application/providers/auth_repository_provider.dart'
    show authRepositoryProvider, sessionStoreProvider;
export 'package:kantin_cerdas/features/auth/data/session/auth_session_store.dart'
    show MemorySessionStore, SecureSessionStore;

typedef AuthPreLogoutCallback = Future<void> Function(AuthSession session);

/// Decoupled registry allowing feature coordinators (e.g. realtime/push cleanup)
/// to revoke device bindings and tear down live streams before logout revokes JWTs.
final authPreLogoutHooksProvider = Provider<List<AuthPreLogoutCallback>>(
  (ref) => <AuthPreLogoutCallback>[],
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(
      AuthController.new,
      retry: (_, _) => null,
    );

class AuthController extends AsyncNotifier<AuthSession?> {
  var _writingSession = false;

  @override
  Future<AuthSession?> build() => ref.watch(authRepositoryProvider).restore();

  Future<void> login(String email, String password) =>
      _mutate((repository) => repository.login(email, password));

  Future<void> loginWithGoogle(String code, String verifier) =>
      _mutate((repository) => repository.loginWithGoogle(code, verifier));

  Future<void> verifyEmailLink(String hash) =>
      _mutate((repository) => repository.verifyEmailLink(hash));

  Future<void> reloadAccount() async {
    if (_writingSession) return;
    _writingSession = true;
    try {
      final repository = ref.read(authRepositoryProvider);
      final session = await repository.restore();
      if (ref.mounted) state = AsyncData(session);
    } finally {
      _writingSession = false;
    }
  }

  Future<void> revalidateOnResume() async {
    try {
      await reloadAccount();
    } on AuthException catch (error, stack) {
      if (ref.mounted && error.code == 'ACCOUNT_INACTIVE') {
        state = AsyncError(error, stack);
      }
    }
  }

  Future<void> completeProfile(String accountId, String name) {
    final session = state.asData?.value;
    if (session == null || session.account.id != accountId) {
      throw const AuthException(
        'INVALID_SESSION',
        'Sesi berakhir. Silakan masuk kembali.',
      );
    }
    return _mutate((repository) => repository.completeProfile(session, name));
  }

  Future<void> logout() async {
    if (_writingSession) return;
    _writingSession = true;
    final session = state.asData?.value;
    final repository = ref.read(authRepositoryProvider);
    final hooks = List<AuthPreLogoutCallback>.of(
      ref.read(authPreLogoutHooksProvider),
    );
    try {
      if (session != null) {
        for (final hook in hooks) {
          try {
            await hook(session);
          } catch (_) {
            // Cleanup hooks must never block logout.
          }
        }
      }
      await repository.logout(session);
      if (ref.mounted) state = const AsyncData(null);
    } finally {
      _writingSession = false;
    }
  }

  Future<void> _mutate(
    Future<AuthSession> Function(AuthRepository) operation,
  ) async {
    if (_writingSession) {
      throw const AuthException(
        'SESSION_BUSY',
        'Tunggu sampai proses sebelumnya selesai.',
      );
    }
    _writingSession = true;
    try {
      final repository = ref.read(authRepositoryProvider);
      final session = await operation(repository);
      if (ref.mounted) state = AsyncData(session);
    } finally {
      _writingSession = false;
    }
  }
}

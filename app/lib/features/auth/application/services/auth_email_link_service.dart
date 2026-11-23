import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_email_link.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';

final authEmailLinkServiceProvider = Provider<AuthEmailLinkService>(
  AuthEmailLinkService.new,
);

class AuthEmailLinkReturnState {
  const AuthEmailLinkReturnState({
    this.emailNotice,
    this.requestNewLink = false,
    this.returnGeneration = 0,
  });

  final String? emailNotice;
  final bool requestNewLink;
  final int returnGeneration;

  AuthEmailLinkReturnState closeWith({
    required String? notice,
    required bool requestNew,
  }) => AuthEmailLinkReturnState(
    emailNotice: notice,
    requestNewLink: requestNew,
    returnGeneration: returnGeneration + 1,
  );
}

bool shouldAcceptIncomingEmailLink({
  required AuthEmailLink? activeLink,
  required AuthEmailLink? incomingLink,
}) {
  return incomingLink != null &&
      (incomingLink.action != activeLink?.action ||
          incomingLink.tokenHash != activeLink?.tokenHash ||
          incomingLink.isCallback != activeLink?.isCallback ||
          incomingLink.isInvalid != activeLink?.isInvalid);
}

/// Coordinates email deep-link verification, non-consuming password recovery
/// pre-checks, password reset confirmation, and email-change confirmation.
class AuthEmailLinkService {
  const AuthEmailLinkService(this._ref);

  final Ref _ref;

  Future<void>? checkRecoveryLinkIfNeeded(AuthEmailLink link) {
    if (link.action == AuthEmailAction.recovery && link.tokenHash != null) {
      return _ref
          .read(authRepositoryProvider)
          .checkPasswordResetLink(link.tokenHash!);
    }
    return null;
  }

  /// Executes the action for [link] using [tokenHash] and returns a completion
  /// message when the link screen should remain open with feedback, or `null`
  /// when the screen should close immediately (signup verification).
  Future<String?> submitEmailLink(
    AuthEmailLink link, {
    required String tokenHash,
    String newPassword = '',
  }) async {
    final repository = _ref.read(authRepositoryProvider);
    final controller = _ref.read(authControllerProvider.notifier);
    switch (link.action) {
      case AuthEmailAction.signup:
        await controller.verifyEmailLink(tokenHash);
        return null;
      case AuthEmailAction.recovery:
        await repository.resetPasswordLink(tokenHash, newPassword);
        return 'Password berhasil diperbarui';
      case AuthEmailAction.emailChange:
        await repository.confirmEmailChange(tokenHash);
        return 'Tautan dikonfirmasi. Buka tautan pada alamat email lainnya jika masih diminta.';
    }
  }

  Future<void> reloadAccountAfterEmailChangeIfNeeded({
    required AuthEmailLink link,
    required String? resultMessage,
    required AuthSession? activeSession,
  }) async {
    if (link.action == AuthEmailAction.emailChange &&
        resultMessage != null &&
        activeSession != null) {
      await _ref.read(authControllerProvider.notifier).reloadAccount();
    }
  }
}

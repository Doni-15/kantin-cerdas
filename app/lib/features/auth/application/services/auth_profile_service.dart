import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/account_photo_provider.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/avatar_picker.dart';

final authProfileServiceProvider = Provider<AuthProfileService>(
  AuthProfileService.new,
);

/// Coordinates authenticated profile completion, avatar replacement with photo
/// cache invalidation, display name updates, and credential changes.
///
/// Session state mutations continue to flow exclusively through
/// [authControllerProvider].
class AuthProfileService {
  const AuthProfileService(this._ref);

  final Ref _ref;

  Future<void> completeRegistrationProfile({
    required String accountId,
    required String displayName,
    PickedAvatar? photo,
    bool useGooglePhoto = false,
    bool Function()? isMounted,
  }) async {
    final session = requireAccountSession(
      _ref.read(authControllerProvider).asData?.value,
      accountId,
    );
    final repository = _ref.read(authRepositoryProvider);
    if (photo != null) {
      await repository.saveAvatar(session, photo.bytes, photo.mediaType);
    } else if (useGooglePhoto) {
      await repository.useGoogleAvatar(session);
    }
    if (!(isMounted?.call() ?? true)) return;
    await _ref
        .read(authControllerProvider.notifier)
        .completeProfile(session.account.id, displayName);
  }

  Future<void> replaceProfilePhoto(String accountId, PickedAvatar photo) async {
    final session = requireAccountSession(
      _ref.read(authControllerProvider).asData?.value,
      accountId,
    );
    await _ref
        .read(authRepositoryProvider)
        .saveAvatar(session, photo.bytes, photo.mediaType);
    _ref.invalidate(accountPhotoProvider(accountId));
  }

  Future<void> updateDisplayName(String accountId, String displayName) => _ref
      .read(authControllerProvider.notifier)
      .completeProfile(accountId, displayName);

  Future<void> changeAccountCredentials({
    required String accountId,
    required String currentPassword,
    String? email,
    String? password,
  }) async {
    final session = requireAccountSession(
      _ref.read(authControllerProvider).asData?.value,
      accountId,
    );
    await _ref
        .read(authRepositoryProvider)
        .changeCredentials(
          session,
          currentPassword,
          email: email,
          password: password,
        );
  }
}

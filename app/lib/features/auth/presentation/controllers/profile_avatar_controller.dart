import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/media/image_picker_port.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/media/media_upload_failure.dart';
import 'package:kantin_cerdas/core/media/media_upload_repository.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';

final class ProfileAvatarState {
  const ProfileAvatarState({
    this.isBusy = false,
    this.errorMessage,
    this.previewBytes,
    this.previewForUrl,
  });

  final bool isBusy;
  final String? errorMessage;
  final Uint8List? previewBytes;
  final String? previewForUrl;
}

final profileAvatarControllerProvider =
    NotifierProvider.autoDispose<ProfileAvatarController, ProfileAvatarState>(
      ProfileAvatarController.new,
    );

class ProfileAvatarController extends Notifier<ProfileAvatarState> {
  String _actorId = '';
  int _sessionGeneration = -1;

  @override
  ProfileAvatarState build() {
    final auth = ref.watch(authStateProvider);
    final notifier = ref.watch(authStateProvider.notifier);
    final user = auth.asData?.value;
    _actorId = (user != null && user.isActive) ? user.id : '';
    _sessionGeneration = notifier.sessionGeneration;
    return const ProfileAvatarState();
  }

  bool _isCurrentSession(String expectedActor, int expectedGeneration) {
    if (!ref.mounted ||
        expectedActor.isEmpty ||
        expectedActor != _actorId ||
        expectedGeneration != _sessionGeneration) {
      return false;
    }
    final auth = ref.read(authStateProvider);
    final notifier = ref.read(authStateProvider.notifier);
    final user = auth.asData?.value;
    return !auth.isLoading &&
        !auth.hasError &&
        user != null &&
        user.isActive &&
        user.id == expectedActor &&
        notifier.sessionGeneration == expectedGeneration;
  }

  Future<bool> pickAndUpload(ImagePickSource source) async {
    if (state.isBusy) {
      return false;
    }
    final actor = _actorId;
    final generation = _sessionGeneration;
    if (!_isCurrentSession(actor, generation)) {
      return false;
    }

    state = ProfileAvatarState(
      isBusy: true,
      previewBytes: state.previewBytes,
      previewForUrl: state.previewForUrl,
    );

    try {
      final picker = ref.read(imagePickerPortProvider);
      final raw = await picker.pickImage(source);
      if (!_isCurrentSession(actor, generation)) {
        return false;
      }
      if (raw == null) {
        state = ProfileAvatarState(
          isBusy: false,
          previewBytes: state.previewBytes,
          previewForUrl: state.previewForUrl,
        );
        return false;
      }

      // Validasi Zero-Trust: Magic Bytes, batas 2 MB, anti-polyglot/script,
      // serta pembuatan nama file acak `{userId}_profile_avatar_{uuid}.{ext}`.
      final validated = ImageSecurityValidator.validateAndPrepare(
        bytes: raw.bytes,
        actorId: actor,
        category: MediaUploadCategory.profileAvatar,
      );

      final uploadRepo = ref.read(mediaUploadRepositoryProvider);
      final uploadedUrl = await uploadRepo.uploadImage(validated);
      if (!_isCurrentSession(actor, generation)) {
        return false;
      }

      final updatedUser = await ref
          .read(authStateProvider.notifier)
          .updateProfileAvatar(avatarUrl: uploadedUrl);
      if (!ref.mounted || updatedUser.id != actor) {
        return false;
      }

      state = ProfileAvatarState(
        isBusy: false,
        previewBytes: validated.bytes,
        previewForUrl: updatedUser.avatarUrl,
      );
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = ProfileAvatarState(
          isBusy: false,
          errorMessage: _mapError(error),
          previewBytes: state.previewBytes,
          previewForUrl: state.previewForUrl,
        );
      }
      return false;
    }
  }

  Future<bool> removeAvatar() async {
    if (state.isBusy) {
      return false;
    }
    final actor = _actorId;
    final generation = _sessionGeneration;
    if (!_isCurrentSession(actor, generation)) {
      return false;
    }

    state = const ProfileAvatarState(isBusy: true);
    try {
      final updatedUser = await ref
          .read(authStateProvider.notifier)
          .updateProfileAvatar(avatarUrl: null);
      if (!ref.mounted || updatedUser.id != actor) {
        return false;
      }
      state = const ProfileAvatarState(isBusy: false);
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = ProfileAvatarState(
          isBusy: false,
          errorMessage: _mapError(error),
        );
      }
      return false;
    }
  }

  String _mapError(Object error) {
    if (error is MediaUploadFailure) {
      return mediaUploadErrorMessage(error);
    }
    if (error is AuthFailure) {
      return authErrorMessage(error);
    }
    return 'Gagal memperbarui foto profil. Silakan coba lagi.';
  }
}

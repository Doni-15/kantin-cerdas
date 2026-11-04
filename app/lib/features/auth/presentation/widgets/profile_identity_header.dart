import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/core/widgets/kc_image_source_sheet.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/profile_avatar_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Header identitas pengguna (foto profil bergaya WhatsApp + nama + username)
/// yang dipakai bersama oleh halaman profil Customer, Owner, dan Admin (DRY).
class ProfileIdentityHeader extends ConsumerWidget {
  const ProfileIdentityHeader({super.key, required this.user});

  final User user;

  Future<void> _handleTapAvatar(
    BuildContext context,
    WidgetRef ref,
    User effectiveUser,
  ) async {
    final avatarState = ref.read(profileAvatarControllerProvider);
    if (avatarState.isBusy) {
      return;
    }
    final hasAvatar =
        effectiveUser.avatarUrl != null &&
        effectiveUser.avatarUrl!.trim().isNotEmpty;

    final choice = await showKcImageSourceSheet(
      context: context,
      title: 'Foto profil',
      canRemove: hasAvatar,
      removeLabel: 'Hapus foto profil',
    );
    if (!context.mounted || choice == null) {
      return;
    }

    final controller = ref.read(profileAvatarControllerProvider.notifier);
    switch (choice) {
      case KcImageRemoveSelected():
        final ok = await controller.removeAvatar();
        if (!context.mounted) return;
        if (ok) {
          KcSnackBar.success(context, 'Foto profil dihapus.');
        } else {
          final err = ref.read(profileAvatarControllerProvider).errorMessage;
          if (err != null) {
            KcSnackBar.error(context, err);
          }
        }
      case KcImagePickSourceSelected(:final source):
        final ok = await controller.pickAndUpload(source);
        if (!context.mounted) return;
        if (ok) {
          KcSnackBar.success(context, 'Foto profil berhasil diperbarui.');
        } else {
          final err = ref.read(profileAvatarControllerProvider).errorMessage;
          if (err != null) {
            KcSnackBar.error(context, err);
          }
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sessionUser = ref.watch(authStateProvider).asData?.value;
    final effectiveUser = (sessionUser != null && sessionUser.id == user.id)
        ? sessionUser
        : user;
    final avatarState = ref.watch(profileAvatarControllerProvider);
    final previewBytes =
        (effectiveUser.avatarUrl != null &&
            effectiveUser.avatarUrl == avatarState.previewForUrl)
        ? avatarState.previewBytes
        : null;

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Ubah foto profil',
          child: InkWell(
            key: const Key('profile_avatar_picker_trigger'),
            customBorder: const CircleBorder(),
            onTap: avatarState.isBusy
                ? null
                : () => _handleTapAvatar(context, ref, effectiveUser),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                KcEntityImage.avatar(
                  imageUrl: effectiveUser.avatarUrl,
                  previewBytes: previewBytes,
                  radius: 36,
                  fallbackIcon: Icons.person_outline,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: avatarState.isBusy
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.photo_camera_outlined,
                              size: 15,
                              color: colors.onPrimary,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: KcSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(effectiveUser.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: KcSpacing.xs / 2),
              Text(
                '@${effectiveUser.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

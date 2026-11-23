import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/account_photo_provider.dart';
import 'package:kantin_cerdas/features/auth/application/providers/avatar_picker_provider.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_profile_service.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/features/auth/presentation/dialogs/account_edit_dialog.dart';
import 'package:kantin_cerdas/features/auth/presentation/dialogs/confirm_photo_change.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/account_profile_header.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/account_settings_card.dart';

class AuthAccountScreen extends ConsumerStatefulWidget {
  const AuthAccountScreen({
    super.key,
    required this.account,
    this.onBack,
    this.onOpenOwnerArea,
  });

  final AuthAccount account;
  final VoidCallback? onBack;
  final VoidCallback? onOpenOwnerArea;

  @override
  ConsumerState<AuthAccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AuthAccountScreen>
    with AuthAction<AuthAccountScreen> {
  Future<void> _updatePhoto() async {
    await runAction(() async {
      final selected = await ref.read(avatarPickerProvider)();
      if (selected == null || !mounted) return;
      final replace = await confirmPhotoChange(
        context,
        title: 'Ganti foto profil?',
        description:
            'Foto yang kamu pilih akan menggantikan foto profil saat ini.',
      );
      if (!replace || !mounted) return;
      await ref
          .read(authProfileServiceProvider)
          .replaceProfilePhoto(widget.account.id, selected);
    });
  }

  Future<void> _edit(AccountEdit edit) async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          AccountEditDialog(account: widget.account, edit: edit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final photo = ref.watch(accountPhotoProvider(widget.account.id));
    final bytes = photo.asData?.value;

    final rawName = widget.account.displayName?.trim();
    final hasCustomName = rawName != null && rawName.isNotEmpty;
    final displayName = hasCustomName ? rawName : widget.account.email;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: widget.onBack == null ? null : 0,
        leading: widget.onBack == null
            ? null
            : BackButton(onPressed: busy ? null : widget.onBack),
        title: const Text('Akun'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthAccountProfileHeader(
                    displayName: displayName,
                    email: widget.account.email,
                    roleLabel: widget.account.role.label,
                    photoBytes: bytes,
                    busy: busy,
                    onUpdatePhoto: _updatePhoto,
                  ),
                  const SizedBox(height: 20),
                  if (problem != null) ...[
                    AuthNotice(problem!),
                    const SizedBox(height: 12),
                  ],
                  if (photo.hasError) ...[
                    Center(
                      child: TextButton.icon(
                        onPressed: busy
                            ? null
                            : () => ref.invalidate(
                                accountPhotoProvider(widget.account.id),
                              ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Coba muat foto lagi'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.account.role == AuthRole.owner &&
                      widget.onOpenOwnerArea != null) ...[
                    FilledButton.icon(
                      onPressed: busy ? null : widget.onOpenOwnerArea,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Masuk Area Owner'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AuthAccountSettingsCard(
                    account: widget.account,
                    hasPhotoBytes: bytes != null,
                    hasCustomName: hasCustomName,
                    customName: rawName,
                    busy: busy,
                    onUpdatePhoto: _updatePhoto,
                    onEdit: _edit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => runAction(
                          ref.read(authControllerProvider.notifier).logout,
                        ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(
                      color: colors.error.withValues(alpha: 0.5),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

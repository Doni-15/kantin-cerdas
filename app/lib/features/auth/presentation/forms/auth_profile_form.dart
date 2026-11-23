import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/account_photo_provider.dart';
import 'package:kantin_cerdas/features/auth/application/providers/avatar_picker_provider.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_profile_service.dart';
import 'package:kantin_cerdas/features/auth/domain/avatar_picker.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/features/auth/presentation/dialogs/confirm_photo_change.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_profile_avatar_preview.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

class AuthProfileForm extends ConsumerStatefulWidget {
  const AuthProfileForm({super.key, required this.account});
  final AuthAccount account;

  @override
  ConsumerState<AuthProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<AuthProfileForm>
    with AuthAction<AuthProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.account.displayName ?? widget.account.suggestedName,
  );
  PickedAvatar? _photo;

  bool get _usesGooglePhoto =>
      !widget.account.hasPhoto && widget.account.googlePhoto != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    await runAction(
      () => ref
          .read(authProfileServiceProvider)
          .completeRegistrationProfile(
            accountId: widget.account.id,
            displayName: name,
            photo: _photo,
            useGooglePhoto: _usesGooglePhoto,
            isMounted: () => mounted,
          ),
    );
  }

  Future<void> _choosePhoto() async {
    await runAction(() async {
      final photo = await ref.read(avatarPickerProvider)();
      if (photo == null || !mounted) return;
      if (_usesGooglePhoto && _photo == null) {
        final replace = await confirmPhotoChange(
          context,
          title: 'Ganti foto Google?',
          description:
              'Foto yang kamu pilih akan digunakan sebagai foto profil Kantin Cerdas.',
        );
        if (!replace || !mounted) return;
      }
      setState(() => _photo = photo);
    });
  }

  Future<void> _leaveRegistration() async {
    final leave = await showKcConfirmDialog(
      context,
      title: 'Kembali ke Masuk?',
      message: 'Kamu bisa melanjutkan pendaftaran dengan masuk lagi.',
      confirmLabel: 'Kembali ke Masuk',
    );
    if (leave && mounted) {
      await runAction(ref.read(authControllerProvider.notifier).logout);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stored = widget.account.hasPhoto
        ? ref.watch(accountPhotoProvider(widget.account.id)).asData?.value
        : null;
    final google = _usesGooglePhoto ? widget.account.googlePhoto : null;

    return AuthLayout(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthRegistrationProgress(
              step: 2,
              onBack: busy ? null : _leaveRegistration,
            ),
            const AuthHeading(
              title: 'Lengkapi profil',
              subtitle: 'Satu langkah lagi, tambahkan foto profilmu.',
              centered: true,
            ),
            if (problem != null) AuthNotice(problem!),
            AuthProfileAvatarPreview(
              selectedPhoto: _photo,
              storedPhotoBytes: stored,
              googlePhotoUrl: google,
            ),
            if (widget.account.displayName == null &&
                widget.account.suggestedName == null)
              TextFormField(
                key: const ValueKey('auth-name'),
                controller: _name,
                enabled: !busy,
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Nama tampilan',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: validateAuthName,
              ),
            const SizedBox(height: KcSpacing.md),
            OutlinedButton.icon(
              onPressed: busy ? null : _choosePhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Pilih foto profil'),
            ),
            if (_photo case final photo?)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  photo.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Batalkan foto yang dipilih',
                  onPressed: busy ? null : () => setState(() => _photo = null),
                  icon: const Icon(Icons.close),
                ),
              ),
            const SizedBox(height: KcSpacing.sm),
            const Text(
              'Foto profil wajib untuk menyelesaikan pendaftaran.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KcSpacing.lg),
            FilledButton(
              onPressed:
                  busy ||
                      (_photo == null &&
                          !widget.account.hasPhoto &&
                          !_usesGooglePhoto)
                  ? null
                  : _submit,
              child: Text(busy ? 'Menyimpan…' : 'Selesaikan Pendaftaran'),
            ),
            const SizedBox(height: KcSpacing.sm),
            const Text(
              'Foto dapat diubah kembali melalui profil.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

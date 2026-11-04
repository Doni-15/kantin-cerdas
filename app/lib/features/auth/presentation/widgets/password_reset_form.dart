import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_brand.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/password_reset_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/password_reset_notice.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class PasswordResetForm extends ConsumerStatefulWidget {
  const PasswordResetForm({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  ConsumerState<PasswordResetForm> createState() => _PasswordResetFormState();
}

class _PasswordResetFormState extends ConsumerState<PasswordResetForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = ref.read(passwordResetControllerProvider);
    if (state.isSubmitting ||
        state.isAcknowledged ||
        state.failure is AuthNotConfiguredFailure) {
      return;
    }
    setState(() => _submitted = true);
    if (_form.currentState?.validate() != true) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(passwordResetControllerProvider.notifier)
        .submit(email: _email.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);
    final theme = Theme.of(context);
    final enabled = !state.isSubmitting && !state.isAcknowledged;
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _form,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: KcBrand(logoSize: 56)),
            const SizedBox(height: KcSpacing.lg),
            ExcludeSemantics(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.lock_reset,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            Semantics(
              header: true,
              child: Text(
                'Pulihkan akses akun',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: KcSpacing.sm),
            const Text(
              'Masukkan email yang digunakan saat mendaftar. '
              'Petunjuk pemulihan akan dikirim jika akun dapat dipulihkan.',
            ),
            const SizedBox(height: KcSpacing.lg),
            KcTextField(
              label: 'Email akun',
              hint: 'nama@contoh.com',
              controller: _email,
              enabled: enabled,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              maxLength: AuthValidator.maxPasswordResetEmailLength,
              autocorrect: false,
              enableSuggestions: false,
              validator: (value) => authFieldErrorMessage(
                field: 'email',
                code: AuthValidator.passwordResetEmail(value ?? '')?.name,
              ),
              onChanged: (_) {
                // Editing clears feedback for the old input, never a pending request.
                if (state.failure != null &&
                    state.failure is! AuthNotConfiguredFailure) {
                  ref
                      .read(passwordResetControllerProvider.notifier)
                      .editEmail();
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: KcSpacing.sm),
            PasswordResetNotice(state: state),
            const SizedBox(height: KcSpacing.md),
            if (state.isAcknowledged)
              KcButton(
                label: 'Kembali ke masuk',
                onPressed: widget.onBackToLogin,
              )
            else
              KcButton(
                label: state.failure == null
                    ? 'Kirim petunjuk pemulihan'
                    : 'Coba kirim lagi',
                isLoading: state.isSubmitting,
                onPressed:
                    state.isSubmitting ||
                        state.failure is AuthNotConfiguredFailure
                    ? null
                    : _submit,
              ),
            const SizedBox(height: KcSpacing.sm),
            if (state.isAcknowledged)
              TextButton(
                onPressed: () {
                  ref
                      .read(passwordResetControllerProvider.notifier)
                      .editEmail();
                  setState(() => _submitted = false);
                },
                child: const Text('Ubah email'),
              )
            else
              TextButton(
                onPressed: state.isSubmitting ? null : widget.onBackToLogin,
                child: const Text('Kembali ke masuk'),
              ),
          ],
        ),
      ),
    );
  }
}

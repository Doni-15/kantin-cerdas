import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_password_field.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/change_password_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  Map<String, String> _fieldErrors = const {};
  bool _submitted = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(changePasswordControllerProvider).isLoading) {
      return;
    }

    setState(() {
      _submitted = true;
      _fieldErrors = const {};
    });

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final currentPassword = _currentController.text;
    final newPassword = _newController.text;

    FocusScope.of(context).unfocus();

    await ref
        .read(changePasswordControllerProvider.notifier)
        .submit(currentPassword: currentPassword, newPassword: newPassword);
  }

  void _handleFailure(Object error) {
    if (error is AuthInvalidCurrentPasswordFailure) {
      setState(() {
        _fieldErrors = {'current_password': authErrorMessage(error)};
      });
      return;
    }

    if (error is AuthValidationFailure) {
      final fieldErrors = <String, String>{};

      for (final field in const ['current_password', 'new_password']) {
        final code = error.fieldErrors[field];

        if (code != null) {
          fieldErrors[field] =
              authFieldErrorMessage(field: field, code: code) ??
              authErrorMessage(error);
        }
      }

      if (fieldErrors.isNotEmpty) {
        setState(() {
          _fieldErrors = fieldErrors;
        });
        return;
      }
    }

    KcSnackBar.error(context, authErrorMessage(error));
  }

  void _handleSuccess() {
    services.TextInput.finishAutofillContext();

    KcSnackBar.success(context, 'Password berhasil diubah.');

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.accountSecurity);
    }
  }

  void _clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) {
      return;
    }

    setState(() {
      _fieldErrors = Map<String, String>.of(_fieldErrors)..remove(field);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(changePasswordControllerProvider, (
      previous,
      next,
    ) {
      if (!mounted || previous?.isLoading != true) {
        return;
      }

      if (next case AsyncError<void>(:final error)) {
        _handleFailure(error);
        return;
      }

      if (next is AsyncData<void>) {
        _handleSuccess();
      }
    });

    final isSubmitting = ref.watch(changePasswordControllerProvider).isLoading;

    final theme = Theme.of(context);

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Password baru minimal '
              '${AuthValidator.minPasswordLength} karakter '
              'dan harus berbeda dari password saat ini.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: KcSpacing.lg),
            KcPasswordField(
              label: 'Password saat ini',
              hint: 'Masukkan password saat ini',
              controller: _currentController,
              enabled: !isSubmitting,
              textInputAction: TextInputAction.next,
              autofillHints: const [services.AutofillHints.password],
              validator: (value) => authFieldErrorMessage(
                field: 'current_password',
                code: AuthValidator.loginPassword(value ?? '')?.name,
              ),
              errorText: _fieldErrors['current_password'],
              onChanged: (_) => _clearFieldError('current_password'),
            ),
            const SizedBox(height: KcSpacing.md),
            KcPasswordField(
              label: 'Password baru',
              hint: 'Masukkan password baru',
              controller: _newController,
              prefixIcon: Icons.lock_reset_outlined,
              enabled: !isSubmitting,
              textInputAction: TextInputAction.next,
              autofillHints: const [services.AutofillHints.newPassword],
              validator: (value) => authFieldErrorMessage(
                field: 'new_password',
                code: AuthValidator.newPassword(
                  currentPassword: _currentController.text,
                  newPassword: value ?? '',
                )?.name,
              ),
              errorText: _fieldErrors['new_password'],
              onChanged: (_) => _clearFieldError('new_password'),
            ),
            const SizedBox(height: KcSpacing.md),
            KcPasswordField(
              label: 'Konfirmasi password baru',
              hint: 'Masukkan ulang password baru',
              controller: _confirmController,
              prefixIcon: Icons.lock_reset_outlined,
              enabled: !isSubmitting,
              autofillHints: const [services.AutofillHints.newPassword],
              validator: (value) => authFieldErrorMessage(
                field: 'confirm_password',
                code: AuthValidator.confirmPassword(
                  password: _newController.text,
                  confirmation: value ?? '',
                )?.name,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: KcSpacing.lg),
            KcButton(
              label: 'Simpan password',
              onPressed: _submit,
              isLoading: isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

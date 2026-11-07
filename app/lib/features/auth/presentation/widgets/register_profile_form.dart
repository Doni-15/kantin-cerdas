import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/auth_destination.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/register_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/register_draft_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class RegisterProfileForm extends ConsumerStatefulWidget {
  const RegisterProfileForm({super.key});

  @override
  ConsumerState<RegisterProfileForm> createState() =>
      _RegisterProfileFormState();
}

class _RegisterProfileFormState extends ConsumerState<RegisterProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  String? _usernameError;
  bool _submitted = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final registerState = ref.read(registerControllerProvider);

    if (registerState.isLoading || registerState.asData?.value != null) {
      return;
    }

    final draft = ref.read(registerDraftProvider);

    if (draft == null || draft.password.isEmpty) {
      context.go(
        continueAuthLocation(GoRouterState.of(context).uri, Routes.register),
      );
      return;
    }

    setState(() {
      _submitted = true;
      _usernameError = null;
    });

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final username = _usernameController.text;

    FocusScope.of(context).unfocus();

    await ref
        .read(registerControllerProvider.notifier)
        .submit(
          name: draft.name,
          username: username,
          email: draft.email,
          password: draft.password,
        );
  }

  void _handleFailure(Object error) {
    final belongsToFirstStep =
        error is AuthEmailTakenFailure ||
        (error is AuthValidationFailure &&
            const [
              'name',
              'email',
              'password',
            ].any(error.fieldErrors.containsKey));

    if (error is AuthFailure && belongsToFirstStep) {
      FocusScope.of(context).unfocus();

      if (context.canPop()) {
        context.pop<AuthFailure>(error);
      } else {
        KcSnackBar.error(context, authErrorMessage(error));
        context.go(
          continueAuthLocation(GoRouterState.of(context).uri, Routes.register),
        );
      }

      return;
    }

    final usernameError = switch (error) {
      AuthUsernameTakenFailure() => authErrorMessage(error),
      AuthValidationFailure(:final fieldErrors) => authFieldErrorMessage(
        field: 'username',
        code: fieldErrors['username'],
      ),
      _ => null,
    };

    if (usernameError != null) {
      setState(() {
        _usernameError = usernameError;
      });
      return;
    }

    KcSnackBar.error(context, authErrorMessage(error));
  }

  void _handleSuccess(User user) {
    services.TextInput.finishAutofillContext();

    ref.read(registerDraftProvider.notifier).clear();

    KcSnackBar.success(
      context,
      user.isActive
          ? 'Akun berhasil dibuat. Silakan masuk.'
          : 'Akun berhasil dibuat. Akunmu belum aktif.',
    );

    context.go(
      continueAuthLocation(GoRouterState.of(context).uri, Routes.login),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(registerControllerProvider, (previous, next) {
      if (!mounted || previous?.isLoading != true) {
        return;
      }

      if (next case AsyncError<User?>(:final error)) {
        _handleFailure(error);
        return;
      }

      final user = next.asData?.value;

      if (user != null) {
        _handleSuccess(user);
      }
    });

    final draft = ref.watch(registerDraftProvider);
    final registerState = ref.watch(registerControllerProvider);

    final isSubmitting = registerState.isLoading;
    final isRegistered = registerState.asData?.value != null;
    final canSubmit =
        draft != null && draft.password.isNotEmpty && !isRegistered;
    final enabled = canSubmit && !isSubmitting;

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
            Text('Satu langkah lagi', style: theme.textTheme.headlineSmall),
            const SizedBox(height: KcSpacing.xs),
            Text(
              'Langkah 2 dari 2 · Pilih username untuk akunmu. '
              'Foto profil dapat diatur setelah kamu masuk.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: KcSpacing.lg),
            KcTextField(
              label: 'Username',
              hint: 'Masukkan username',
              controller: _usernameController,
              prefixIcon: Icons.alternate_email,
              enabled: enabled,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: services.SmartDashesType.disabled,
              smartQuotesType: services.SmartQuotesType.disabled,
              autofillHints: const [services.AutofillHints.newUsername],
              validator: (value) => authFieldErrorMessage(
                field: 'username',
                code: AuthValidator.username(value ?? '')?.name,
              ),
              errorText: _usernameError,
              onChanged: (_) {
                if (_usernameError != null) {
                  setState(() {
                    _usernameError = null;
                  });
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: KcSpacing.lg),
            KcButton(
              label: 'Buat akun',
              onPressed: canSubmit ? _submit : null,
              isLoading: isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

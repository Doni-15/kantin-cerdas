import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/auth_destination.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/config/app_feature_flags.dart';
import 'package:kantin_cerdas/core/widgets/kc_brand.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_logo.dart';
import 'package:kantin_cerdas/core/widgets/kc_password_field.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/login_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  Map<String, String> _fieldErrors = const {};
  bool _submitted = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(loginControllerProvider).isLoading) {
      return;
    }

    setState(() {
      _submitted = true;
      _fieldErrors = const {};
    });

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final identifier = _identifierController.text;
    final password = _passwordController.text;

    FocusScope.of(context).unfocus();

    await ref
        .read(loginControllerProvider.notifier)
        .submit(identifier: identifier, password: password);
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
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      if (!mounted) {
        return;
      }

      if (next case AsyncError<void>(:final error)) {
        setState(() {
          _fieldErrors = error is AuthValidationFailure
              ? error.fieldErrors
              : const {};
        });

        KcSnackBar.error(context, authErrorMessage(error));
        return;
      }

      if (previous?.isLoading == true && next is AsyncData<void>) {
        services.TextInput.finishAutofillContext();
      }
    });

    final isLoading = ref.watch(loginControllerProvider).isLoading;
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
            const Center(child: KcBrand(logoSize: 68)),
            const SizedBox(height: KcSpacing.lg),
            Text(
              'Selamat datang kembali!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: KcSpacing.xs),
            Text(
              'Masuk untuk melanjutkan ke KantinCerdas.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: KcSpacing.lg),
            KcTextField(
              label: 'Username atau email',
              hint: 'Masukkan username atau email',
              controller: _identifierController,
              prefixIcon: Icons.person_outline,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: services.SmartDashesType.disabled,
              smartQuotesType: services.SmartQuotesType.disabled,
              autofillHints: const [services.AutofillHints.username],
              validator: (value) => authFieldErrorMessage(
                field: 'identifier',
                code: AuthValidator.identifier(value ?? '')?.name,
              ),
              errorText: authFieldErrorMessage(
                field: 'identifier',
                code: _fieldErrors['identifier'],
              ),
              onChanged: (_) => _clearFieldError('identifier'),
            ),
            const SizedBox(height: KcSpacing.md),
            KcPasswordField(
              label: 'Password',
              hint: 'Masukkan password',
              controller: _passwordController,
              enabled: !isLoading,
              validator: (value) => authFieldErrorMessage(
                field: 'password',
                code: AuthValidator.loginPassword(value ?? '')?.name,
              ),
              errorText: authFieldErrorMessage(
                field: 'password',
                code: _fieldErrors['password'],
              ),
              onChanged: (_) => _clearFieldError('password'),
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        context.push(
                          continueAuthLocation(
                            GoRouterState.of(context).uri,
                            Routes.resetPassword,
                          ),
                        );
                      },
                child: const Text('Lupa password?'),
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            KcButton(label: 'Masuk', onPressed: _submit, isLoading: isLoading),
            if (AppFeatureFlags.enableGoogleAuth) ...[
              const SizedBox(height: KcSpacing.lg),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KcSpacing.sm,
                    ),
                    child: Text('atau', style: theme.textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: KcSpacing.lg),
              KcButton(
                label: 'Masuk dengan Google',
                variant: KcButtonVariant.outlined,
                leading: const KcLogo(
                  assetPath: 'assets/images/logos/google_logo.png',
                  size: 20,
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        KcSnackBar.info(
                          context,
                          'Login dengan Google belum tersedia.',
                        );
                      },
              ),
            ],
            const SizedBox(height: KcSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: KcSpacing.xs,
              children: [
                const Text('Belum punya akun?'),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.push(
                            continueAuthLocation(
                              GoRouterState.of(context).uri,
                              Routes.register,
                            ),
                          );
                        },
                  child: const Text('Daftar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

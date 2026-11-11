import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/auth_destination.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/config/app_feature_flags.dart';
import 'package:kantin_cerdas/core/session/auth_repository.dart';
import 'package:kantin_cerdas/core/widgets/kc_brand.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_logo.dart';
import 'package:kantin_cerdas/core/widgets/kc_password_field.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/register_draft_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  Map<String, String> _fieldErrors = const {};

  bool _submitted = false;
  bool _continuing = false;

  @override
  void initState() {
    super.initState();

    final draft = ref.read(registerDraftProvider);

    _nameController = TextEditingController(text: draft?.name);
    _emailController = TextEditingController(text: draft?.email);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_continuing) {
      return;
    }

    setState(() {
      _submitted = true;
      _fieldErrors = const {};
    });

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _continuing = true;
    });

    try {
      final email = _emailController.text.trim();
      final isAvailable = await _isEmailAvailable(email);
      if (!mounted || isAvailable == null) {
        return;
      }

      if (!isAvailable) {
        _showReturnedFailure(const AuthEmailTakenFailure());
        return;
      }

      final existingDraft = ref.read(registerDraftProvider);
      ref.read(registerDraftProvider.notifier).setDraft(
            RegisterDraft(
              name: _nameController.text.trim(),
              email: email,
              password: _passwordController.text,
              avatarPreviewBytes: existingDraft?.avatarPreviewBytes,
            ),
          );

      final failure = await context.push<AuthFailure>(
        continueAuthLocation(
          GoRouterState.of(context).uri,
          Routes.registerProfile,
        ),
      );

      ref.read(registerDraftProvider.notifier).clearPassword();

      if (!mounted || failure == null) {
        return;
      }

      _showReturnedFailure(failure);
    } finally {
      if (mounted) {
        setState(() {
          _continuing = false;
        });
      }
    }
  }

  Future<bool?> _isEmailAvailable(String email) async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      return await authRepository.isEmailAvailable(email: email);
    } on AuthNotConfiguredFailure {
      return true;
    } on AuthFailure catch (failure) {
      if (mounted) {
        _showReturnedFailure(failure);
      }
      return null;
    }
  }

  void _showReturnedFailure(AuthFailure failure) {
    final fieldErrors = <String, String>{};

    if (failure is AuthValidationFailure) {
      for (final entry in failure.fieldErrors.entries) {
        fieldErrors[entry.key] =
            authFieldErrorMessage(field: entry.key, code: entry.value) ??
            authErrorMessage(failure);
      }
    } else if (failure is AuthEmailTakenFailure) {
      fieldErrors['email'] = authErrorMessage(failure);
    }

    setState(() {
      _fieldErrors = fieldErrors;
    });

    KcSnackBar.error(context, authErrorMessage(failure));
  }

  void _clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) {
      return;
    }

    setState(() {
      _fieldErrors = Map<String, String>.of(_fieldErrors)..remove(field);
    });
  }

  void _returnToLogin() {
    ref.read(registerDraftProvider.notifier).clear();
    FocusScope.of(context).unfocus();
    context.go(
      continueAuthLocation(GoRouterState.of(context).uri, Routes.login),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(registerDraftProvider);

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
              'Buat akun baru',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: KcSpacing.xs),
            Text(
              'Langkah 1 dari 2 · Isi data akunmu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: KcSpacing.lg),
            KcTextField(
              label: 'Nama lengkap',
              hint: 'Masukkan nama lengkap',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              enabled: !_continuing,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autocorrect: false,
              autofillHints: const [services.AutofillHints.name],
              validator: (value) => authFieldErrorMessage(
                field: 'name',
                code: AuthValidator.name(value ?? '')?.name,
              ),
              errorText: _fieldErrors['name'],
              onChanged: (_) => _clearFieldError('name'),
            ),
            const SizedBox(height: KcSpacing.md),
            KcTextField(
              label: 'Email',
              hint: 'Masukkan alamat email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              enabled: !_continuing,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: services.SmartDashesType.disabled,
              smartQuotesType: services.SmartQuotesType.disabled,
              autofillHints: const [services.AutofillHints.email],
              validator: (value) => authFieldErrorMessage(
                field: 'email',
                code: AuthValidator.email(value ?? '')?.name,
              ),
              errorText: _fieldErrors['email'],
              onChanged: (_) => _clearFieldError('email'),
            ),
            const SizedBox(height: KcSpacing.md),
            KcPasswordField(
              label: 'Password',
              hint: 'Buat password',
              controller: _passwordController,
              enabled: !_continuing,
              textInputAction: TextInputAction.next,
              autofillHints: const [services.AutofillHints.newPassword],
              validator: (value) => authFieldErrorMessage(
                field: 'password',
                code: AuthValidator.password(value ?? '')?.name,
              ),
              errorText: _fieldErrors['password'],
              onChanged: (_) => _clearFieldError('password'),
            ),
            const SizedBox(height: KcSpacing.md),
            KcPasswordField(
              label: 'Konfirmasi password',
              hint: 'Masukkan ulang password',
              controller: _confirmPasswordController,
              enabled: !_continuing,
              autofillHints: const [services.AutofillHints.newPassword],
              validator: (value) => authFieldErrorMessage(
                field: 'confirm_password',
                code: AuthValidator.confirmPassword(
                  password: _passwordController.text,
                  confirmation: value ?? '',
                )?.name,
              ),
              onSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: KcSpacing.lg),
            KcButton(
              label: 'Lanjut',
              onPressed: _continuing ? null : _continue,
              isLoading: _continuing,
            ),
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
                label: 'Daftar dengan Google',
                variant: KcButtonVariant.outlined,
                leading: const KcLogo(
                  assetPath: 'assets/images/logos/google_logo.png',
                  size: 20,
                ),
                onPressed: _continuing
                    ? null
                    : () {
                        KcSnackBar.info(
                          context,
                          'Daftar dengan Google belum tersedia.',
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
                const Text('Sudah punya akun?'),
                TextButton(
                  onPressed: _continuing ? null : _returnToLogin,
                  child: const Text('Masuk'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
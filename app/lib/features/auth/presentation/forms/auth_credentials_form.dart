import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/google_oauth_provider.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_credentials_service.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/features/auth/presentation/forms/modes/email_verification_mode.dart';
import 'package:kantin_cerdas/features/auth/presentation/forms/modes/login_mode.dart';
import 'package:kantin_cerdas/features/auth/presentation/forms/modes/password_reset_mode.dart';
import 'package:kantin_cerdas/features/auth/presentation/forms/modes/registration_mode.dart';

enum _FormMode { login, registration, verify, requestReset }

class AuthCredentialsForm extends ConsumerStatefulWidget {
  const AuthCredentialsForm({
    super.key,
    this.initialNotice,
    this.requestNewLink = false,
    this.returnGeneration = 0,
  });

  final String? initialNotice;
  final bool requestNewLink;
  final int returnGeneration;

  @override
  ConsumerState<AuthCredentialsForm> createState() => _CredentialsFormState();
}

class _CredentialsFormState extends ConsumerState<AuthCredentialsForm>
    with AuthAction<AuthCredentialsForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  late _FormMode _mode = widget.requestNewLink
      ? _FormMode.requestReset
      : _FormMode.login;
  bool _obscured = true;
  late String? _information = widget.initialNotice;
  VoidCallback? _cancelGoogle;

  @override
  void didUpdateWidget(covariant AuthCredentialsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.returnGeneration != oldWidget.returnGeneration) {
      _changeMode(
        widget.requestNewLink ? _FormMode.requestReset : _FormMode.login,
        information: widget.initialNotice,
      );
    }
  }

  @override
  void dispose() {
    _cancelGoogle?.call();
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    if (busy) return;
    FocusScope.of(context).unfocus();
    await runAction(() async {
      setState(() => _information = null);
      await ref
          .read(authCredentialsServiceProvider)
          .signInWithGoogle(
            onCancelChanged: (cancel) {
              if (mounted) setState(() => _cancelGoogle = cancel);
            },
            isMounted: () => mounted,
          );
    });
  }

  void _startGoogle(bool googleAvailable) {
    if (!googleAvailable) {
      setState(() => problem = authGoogleClientDisabledException.message);
    } else {
      _loginWithGoogle();
    }
  }

  void _togglePasswordVisibility() => setState(() => _obscured = !_obscured);

  Future<void> _resendVerificationEmail() => runAction(() async {
    await ref
        .read(authCredentialsServiceProvider)
        .resendVerificationEmail(_email.text.trim());
    if (mounted) {
      setState(
        () => _information =
            'Periksa kotak masuk dan folder spam untuk email verifikasi terbaru.',
      );
    }
  });

  void _changeMode(_FormMode mode, {String? information}) {
    final email = _email.text;
    final name = _name.text;
    // Keep the credential only in memory while this verification screen is open.
    final password = mode == _FormMode.verify ? _password.text : '';
    _form.currentState?.reset();
    _email.text = email;
    _name.text = name;
    _password.text = password;
    setState(() {
      _mode = mode;
      _obscured = true;
      _information = information;
      problem = null;
    });
  }

  Future<void> _submit() async {
    if (busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final password = _password.text;
    final controller = ref.read(authControllerProvider.notifier);
    final credentialsService = ref.read(authCredentialsServiceProvider);
    final submittedMode = _mode;
    await runAction(() async {
      switch (submittedMode) {
        case _FormMode.login:
          try {
            await controller.login(email, password);
          } on AuthException catch (error) {
            if (error.code != 'EMAIL_NOT_VERIFIED') rethrow;
            if (mounted) {
              _changeMode(
                _FormMode.verify,
                information: 'Periksa email verifikasi untuk akun ini.',
              );
            }
          }
        case _FormMode.registration:
          await credentialsService.register(
            email: email,
            password: password,
            displayName: _name.text.trim(),
          );
          if (mounted) _changeMode(_FormMode.verify);
        case _FormMode.verify:
          await controller.login(email, password);
        case _FormMode.requestReset:
          await credentialsService.requestPasswordReset(email);
          if (mounted) {
            setState(
              () => _information =
                  'Jika alamat email terdaftar dan mendukung pemulihan password, instruksi pemulihan akan dikirim.',
            );
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = _mode;
    final login = mode == _FormMode.login;
    final googleAvailable = ref.watch(googleOAuthProvider) != null;

    // Keep one form and autofill scope across all credential modes.
    return PopScope(
      canPop: !busy && login,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy && !login) {
          _changeMode(_FormMode.login);
        }
      },
      child: AuthLayout(
        showLogo: login,
        child: AutofillGroup(
          onDisposeAction: AutofillContextAction.cancel,
          child: Form(
            key: _form,
            child: switch (mode) {
              _FormMode.login => AuthLoginModeContent(
                emailController: _email,
                passwordController: _password,
                busy: busy,
                obscured: _obscured,
                information: _information,
                problem: problem,
                cancelGoogle: _cancelGoogle,
                onToggleObscured: _togglePasswordVisibility,
                onSubmit: _submit,
                onStartGoogle: () => _startGoogle(googleAvailable),
                onForgotPassword: () => _changeMode(_FormMode.requestReset),
                onSwitchToRegister: () => _changeMode(_FormMode.registration),
              ),
              _FormMode.registration => AuthRegistrationModeContent(
                nameController: _name,
                emailController: _email,
                passwordController: _password,
                busy: busy,
                obscured: _obscured,
                information: _information,
                problem: problem,
                cancelGoogle: _cancelGoogle,
                onBackToLogin: () => _changeMode(_FormMode.login),
                onToggleObscured: _togglePasswordVisibility,
                onSubmit: _submit,
                onStartGoogle: () => _startGoogle(googleAvailable),
              ),
              _FormMode.verify => AuthEmailVerificationModeContent(
                email: _email.text.trim(),
                busy: busy,
                information: _information,
                problem: problem,
                cancelGoogle: _cancelGoogle,
                onBackToLogin: () => _changeMode(_FormMode.login),
                onSubmit: _submit,
                onResendVerificationEmail: _resendVerificationEmail,
              ),
              _FormMode.requestReset => AuthPasswordResetModeContent(
                emailController: _email,
                busy: busy,
                information: _information,
                problem: problem,
                cancelGoogle: _cancelGoogle,
                onBackToLogin: () => _changeMode(_FormMode.login),
                onSubmit: _submit,
              ),
            },
          ),
        ),
      ),
    );
  }
}

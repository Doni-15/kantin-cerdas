import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_credential_fields.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_google_section.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_mode_footers.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthLoginModeContent extends StatelessWidget {
  const AuthLoginModeContent({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.busy,
    required this.obscured,
    required this.information,
    required this.problem,
    required this.cancelGoogle,
    required this.onToggleObscured,
    required this.onSubmit,
    required this.onStartGoogle,
    required this.onForgotPassword,
    required this.onSwitchToRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool busy;
  final bool obscured;
  final String? information;
  final String? problem;
  final VoidCallback? cancelGoogle;
  final VoidCallback onToggleObscured;
  final VoidCallback onSubmit;
  final VoidCallback onStartGoogle;
  final VoidCallback onForgotPassword;
  final VoidCallback onSwitchToRegister;

  @override
  Widget build(BuildContext context) {
    final hintStyle = Theme.of(context).inputDecorationTheme.hintStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'Selamat datang kembali',
          subtitle: 'Masuk ke akunmu',
          centered: true,
        ),
        if (information != null) AuthNotice(information!, isError: false),
        const AuthFieldLabel('Email'),
        AuthEmailField(
          controller: emailController,
          enabled: !busy,
          login: true,
          showPassword: true,
          hintStyle: hintStyle,
          onSubmitted: onSubmit,
        ),
        const SizedBox(height: KcSpacing.md),
        const AuthFieldLabel('Password'),
        AuthPasswordField(
          controller: passwordController,
          enabled: !busy,
          login: true,
          registering: false,
          obscured: obscured,
          hintStyle: hintStyle,
          onToggleObscured: onToggleObscured,
          onSubmitted: onSubmit,
        ),
        AuthForgotPasswordButton(enabled: !busy, onPressed: onForgotPassword),
        if (problem != null) AuthNotice(problem!),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: Text(
            busy && cancelGoogle == null ? 'Sedang masuk...' : 'Masuk',
          ),
        ),
        AuthGoogleSignInSection(
          enabled: !busy,
          onPressed: onStartGoogle,
          onCancel: cancelGoogle,
        ),
        AuthModePromptFooter(
          prompt: 'Belum punya akun?',
          actionLabel: 'Daftar',
          enabled: !busy,
          onPressed: onSwitchToRegister,
        ),
      ],
    );
  }
}

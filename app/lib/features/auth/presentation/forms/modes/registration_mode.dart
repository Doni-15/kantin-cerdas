import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_credential_fields.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_google_section.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_mode_footers.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthRegistrationModeContent extends StatelessWidget {
  const AuthRegistrationModeContent({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.busy,
    required this.obscured,
    required this.information,
    required this.problem,
    required this.cancelGoogle,
    required this.onBackToLogin,
    required this.onToggleObscured,
    required this.onSubmit,
    required this.onStartGoogle,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool busy;
  final bool obscured;
  final String? information;
  final String? problem;
  final VoidCallback? cancelGoogle;
  final VoidCallback onBackToLogin;
  final VoidCallback onToggleObscured;
  final VoidCallback onSubmit;
  final VoidCallback onStartGoogle;

  @override
  Widget build(BuildContext context) {
    final hintStyle = Theme.of(context).inputDecorationTheme.hintStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthRegistrationProgress(step: 1, onBack: busy ? null : onBackToLogin),
        const AuthHeading(
          title: 'Buat akun',
          subtitle: 'Isi informasi dasar untuk memulai.',
          centered: true,
        ),
        if (information != null) AuthNotice(information!, isError: false),
        if (problem != null) AuthNotice(problem!),
        AuthRegistrationNameField(controller: nameController, enabled: !busy),
        const SizedBox(height: KcSpacing.md),
        AuthEmailField(
          controller: emailController,
          enabled: !busy,
          login: false,
          showPassword: true,
          hintStyle: hintStyle,
          onSubmitted: onSubmit,
        ),
        const SizedBox(height: KcSpacing.md),
        AuthPasswordField(
          controller: passwordController,
          enabled: !busy,
          login: false,
          registering: true,
          obscured: obscured,
          hintStyle: hintStyle,
          onToggleObscured: onToggleObscured,
          onSubmitted: onSubmit,
        ),
        const SizedBox(height: KcSpacing.lg),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: Text(
            busy && cancelGoogle == null ? 'Memproses…' : 'Lanjutkan',
          ),
        ),
        AuthGoogleSignInSection(
          enabled: !busy,
          onPressed: onStartGoogle,
          onCancel: cancelGoogle,
        ),
        AuthModePromptFooter(
          prompt: 'Sudah punya akun?',
          actionLabel: 'Masuk',
          enabled: !busy,
          onPressed: onBackToLogin,
        ),
      ],
    );
  }
}

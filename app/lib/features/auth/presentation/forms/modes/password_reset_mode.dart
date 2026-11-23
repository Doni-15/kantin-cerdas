import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_credential_fields.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_mode_footers.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthPasswordResetModeContent extends StatelessWidget {
  const AuthPasswordResetModeContent({
    super.key,
    required this.emailController,
    required this.busy,
    required this.information,
    required this.problem,
    required this.cancelGoogle,
    required this.onBackToLogin,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final bool busy;
  final String? information;
  final String? problem;
  final VoidCallback? cancelGoogle;
  final VoidCallback onBackToLogin;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final hintStyle = Theme.of(context).inputDecorationTheme.hintStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BackButton(onPressed: busy ? null : onBackToLogin),
        ),
        const Center(child: Text('Pemulihan akun')),
        const AuthHeading(
          title: 'Lupa password?',
          subtitle:
              'Masukkan alamat email akunmu. Kami akan mengirim tautan untuk mengatur ulang password.',
          centered: true,
        ),
        if (information != null) AuthNotice(information!, isError: false),
        if (problem != null) AuthNotice(problem!),
        const AuthGoogleRecoveryNotice(),
        AuthEmailField(
          controller: emailController,
          enabled: !busy,
          login: false,
          showPassword: false,
          hintStyle: hintStyle,
          onSubmitted: onSubmit,
        ),
        const SizedBox(height: KcSpacing.lg),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: Text(
            busy && cancelGoogle == null ? 'Memproses…' : 'Kirim tautan reset',
          ),
        ),
        AuthModePromptFooter(
          prompt: 'Ingat password?',
          actionLabel: 'Masuk',
          enabled: !busy,
          onPressed: onBackToLogin,
        ),
      ],
    );
  }
}

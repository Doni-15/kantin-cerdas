import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/auth_verify_email_section.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthEmailVerificationModeContent extends StatelessWidget {
  const AuthEmailVerificationModeContent({
    super.key,
    required this.email,
    required this.busy,
    required this.information,
    required this.problem,
    required this.cancelGoogle,
    required this.onBackToLogin,
    required this.onSubmit,
    required this.onResendVerificationEmail,
  });

  final String email;
  final bool busy;
  final String? information;
  final String? problem;
  final VoidCallback? cancelGoogle;
  final VoidCallback onBackToLogin;
  final VoidCallback onSubmit;
  final VoidCallback onResendVerificationEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BackButton(onPressed: busy ? null : onBackToLogin),
        ),
        const AuthVerifyEmailHeader(),
        const AuthHeading(
          title: 'Cek email kamu',
          subtitle:
              'Jika alamat email dapat didaftarkan, kami akan mengirim tautan verifikasi.',
          centered: true,
        ),
        if (information != null) AuthNotice(information!, isError: false),
        if (problem != null) AuthNotice(problem!),
        AuthVerifyEmailInstructions(email: email),
        const SizedBox(height: KcSpacing.lg),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: Text(
            busy && cancelGoogle == null
                ? 'Memproses…'
                : 'Saya sudah verifikasi',
          ),
        ),
        AuthVerifyEmailFooter(
          enabled: !busy,
          onResend: onResendVerificationEmail,
          onBackToLogin: onBackToLogin,
        ),
      ],
    );
  }
}

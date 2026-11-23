import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthVerifyEmailHeader extends StatelessWidget {
  const AuthVerifyEmailHeader({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Center(child: Text('Verifikasi email')),
      SizedBox(height: KcSpacing.md),
      Center(child: CircleAvatar(child: Icon(Icons.mark_email_read_outlined))),
      SizedBox(height: KcSpacing.md),
    ],
  );
}

class AuthVerifyEmailInstructions extends StatelessWidget {
  const AuthVerifyEmailInstructions({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(KcRadius.control),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.md),
          child: Text(email, textAlign: TextAlign.center),
        ),
      ),
      const SizedBox(height: KcSpacing.md),
      const Text(
        'Buka email dan tekan tautan verifikasi untuk mengaktifkan akunmu.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class AuthVerifyEmailFooter extends StatelessWidget {
  const AuthVerifyEmailFooter({
    super.key,
    required this.enabled,
    required this.onResend,
    required this.onBackToLogin,
  });

  final bool enabled;
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Belum menerima email?'),
          TextButton(
            onPressed: enabled ? onResend : null,
            child: const Text('Kirim ulang email'),
          ),
        ],
      ),
      TextButton(
        onPressed: enabled ? onBackToLogin : null,
        child: const Text('Kembali ke Masuk'),
      ),
    ],
  );
}

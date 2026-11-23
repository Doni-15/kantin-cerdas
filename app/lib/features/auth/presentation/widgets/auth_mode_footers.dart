import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthForgotPasswordButton extends StatelessWidget {
  const AuthForgotPasswordButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: TextButton(
      onPressed: enabled ? onPressed : null,
      child: const Text('Lupa password?'),
    ),
  );
}

class AuthGoogleRecoveryNotice extends StatelessWidget {
  const AuthGoogleRecoveryNotice({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: KcSpacing.md),
    child: Text('Jika masuk dengan Google, pulihkan akun melalui Google.'),
  );
}

class AuthModePromptFooter extends StatelessWidget {
  const AuthModePromptFooter({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
  });

  final String prompt;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(prompt),
      TextButton(
        onPressed: enabled ? onPressed : null,
        child: Text(actionLabel),
      ),
    ],
  );
}

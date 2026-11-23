import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthGoogleSignInSection extends StatelessWidget {
  const AuthGoogleSignInSection({
    super.key,
    required this.enabled,
    required this.onPressed,
    this.onCancel,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: KcSpacing.sm),
      const Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: KcSpacing.sm),
            child: Text('atau'),
          ),
          Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: KcSpacing.sm),
      OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Image.asset(
          'assets/images/logos/google_logo.png',
          height: 19,
          width: 19,
          excludeFromSemantics: true,
        ),
        label: const Text('Lanjutkan dengan Google'),
      ),
      if (onCancel != null)
        TextButton(
          onPressed: onCancel,
          child: const Text('Batalkan proses Google'),
        ),
    ],
  );
}

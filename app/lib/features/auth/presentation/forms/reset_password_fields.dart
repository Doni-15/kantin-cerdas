import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/presentation/forms/auth_password_confirmation.dart';
import 'package:kantin_cerdas/features/auth/presentation/validators/auth_validators.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

List<Widget> resetPasswordFields({
  required TextEditingController password,
  required TextEditingController confirmation,
  required bool busy,
  required bool obscured,
  required VoidCallback toggleObscured,
}) => [
  TextFormField(
    key: const ValueKey('auth-link-password'),
    controller: password,
    enabled: !busy,
    obscureText: obscured,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: const [AutofillHints.newPassword],
    decoration: InputDecoration(
      labelText: 'Password baru',
      helperText: 'Minimal 15 karakter',
      suffixIcon: IconButton(
        tooltip: obscured
            ? 'Tampilkan password baru'
            : 'Sembunyikan password baru',
        onPressed: busy ? null : toggleObscured,
        icon: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (value) => validateAuthPassword(value, isNew: true),
  ),
  const SizedBox(height: KcSpacing.md),
  AuthPasswordConfirmation(
    controller: confirmation,
    password: password,
    enabled: !busy,
  ),
  const SizedBox(height: KcSpacing.lg),
];

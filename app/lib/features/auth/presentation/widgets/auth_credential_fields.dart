import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/presentation/validators/auth_validators.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KcSpacing.xs),
    child: Text(label, style: Theme.of(context).textTheme.labelLarge),
  );
}

class AuthRegistrationNameField extends StatelessWidget {
  const AuthRegistrationNameField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('auth-registration-name'),
    controller: controller,
    enabled: enabled,
    autofillHints: const [AutofillHints.name],
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    decoration: const InputDecoration(
      labelText: 'Nama lengkap',
      hintText: 'Nama lengkap kamu',
    ),
    validator: validateAuthName,
  );
}

class AuthEmailField extends StatelessWidget {
  const AuthEmailField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.login,
    required this.showPassword,
    required this.hintStyle,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool login;
  final bool showPassword;
  final TextStyle? hintStyle;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('auth-email'),
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.emailAddress,
    textInputAction: showPassword ? TextInputAction.next : TextInputAction.done,
    autofillHints: const [AutofillHints.email],
    autocorrect: false,
    decoration: InputDecoration(
      labelText: login ? null : 'Email',
      hintText: login ? null : 'nama@email.com',
      hint: login
          ? Text('nama@email.com', semanticsLabel: 'Email', style: hintStyle)
          : null,
    ),
    validator: validateAuthEmail,
    onFieldSubmitted: showPassword ? null : (_) => onSubmitted(),
  );
}

class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.login,
    required this.registering,
    required this.obscured,
    required this.hintStyle,
    required this.onToggleObscured,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool login;
  final bool registering;
  final bool obscured;
  final TextStyle? hintStyle;
  final VoidCallback onToggleObscured;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('auth-password'),
    controller: controller,
    enabled: enabled,
    obscureText: obscured,
    enableSuggestions: false,
    autocorrect: false,
    autofillHints: [
      registering ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: TextInputAction.done,
    onFieldSubmitted: (_) => onSubmitted(),
    decoration: InputDecoration(
      labelText: login ? null : 'Password',
      hintText: registering ? 'Buat password' : null,
      hint: login
          ? Text(
              'Masukkan password',
              semanticsLabel: 'Password',
              style: hintStyle,
            )
          : null,
      helperText: registering ? 'Minimal 15 karakter' : null,
      suffixIcon: IconButton(
        tooltip: obscured ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
        onPressed: enabled ? onToggleObscured : null,
        icon: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (value) => validateAuthPassword(value, isNew: registering),
  );
}

import 'package:flutter/material.dart';

class AuthPasswordConfirmation extends StatefulWidget {
  const AuthPasswordConfirmation({
    super.key,
    required this.controller,
    required this.password,
    required this.enabled,
  });

  final TextEditingController controller;
  final TextEditingController password;
  final bool enabled;

  @override
  State<AuthPasswordConfirmation> createState() => _PasswordConfirmationState();
}

class _PasswordConfirmationState extends State<AuthPasswordConfirmation> {
  var _obscured = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: _obscured,
    autocorrect: false,
    enableSuggestions: false,
    decoration: InputDecoration(
      labelText: 'Konfirmasi password',
      suffixIcon: IconButton(
        tooltip: _obscured
            ? 'Tampilkan konfirmasi password'
            : 'Sembunyikan konfirmasi password',
        onPressed: widget.enabled
            ? () => setState(() => _obscured = !_obscured)
            : null,
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (value) =>
        value == widget.password.text ? null : 'Password tidak cocok.',
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';

class KcPasswordField extends StatefulWidget {
  const KcPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.errorText,
    this.prefixIcon = Icons.lock_outline,
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [services.AutofillHints.password],
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final IconData? prefixIcon;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<KcPasswordField> createState() => _KcPasswordFieldState();
}

class _KcPasswordFieldState extends State<KcPasswordField> {
  bool _obscureText = true;

  @override
  void didUpdateWidget(covariant KcPasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _obscureText = true;
    }
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KcTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      validator: widget.validator,
      errorText: widget.errorText,
      prefixIcon: widget.prefixIcon,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      keyboardType: TextInputType.visiblePassword,
      textCapitalization: TextCapitalization.none,
      obscureText: _obscureText,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: services.SmartDashesType.disabled,
      smartQuotesType: services.SmartQuotesType.disabled,
      maxLines: 1,

      suffixIcon: IconButton(
        onPressed: widget.enabled ? _toggleVisibility : null,
        tooltip: _obscureText ? 'Tampilkan password' : 'Sembunyikan password',
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    );
  }
}

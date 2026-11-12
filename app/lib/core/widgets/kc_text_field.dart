import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

class KcTextField extends StatelessWidget {
  const KcTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableIMEPersonalizedLearning = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.maxLines = 1,
    this.maxLength,
  }) : assert(maxLines == null || maxLines > 0),
       assert(maxLength == null || maxLength > 0),
       assert(!obscureText || maxLines == 1);

  final String label;

  /// Dibuat dan di-dispose oleh halaman atau form pemiliknya.
  final TextEditingController controller;

  final String? hint;
  final FormFieldValidator<String>? validator;

  /// Pesan kesalahan dari controller yang sudah diterjemahkan oleh UI.
  final String? errorText;

  final IconData? prefixIcon;
  final Widget? suffixIcon;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final bool enabled;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableIMEPersonalizedLearning;

  final services.SmartDashesType? smartDashesType;
  final services.SmartQuotesType? smartQuotesType;

  final int? maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: services.MaxLengthEnforcement.enforced,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
        alignLabelWithHint: maxLines != 1,
      ),
    );
  }
}

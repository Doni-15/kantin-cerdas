import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class KcTextField extends StatelessWidget {
  const KcTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  final bool enabled;
  final bool autofocus;
  
  final int? maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Field
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: KcSpacing.xs),

        // Input Field
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          enabled: enabled,
          autofocus: autofocus,
          maxLines: maxLines,
          onChanged: onChanged,
          
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffixIcon,
            alignLabelWithHint: maxLines != null && maxLines! > 1,
            
            prefixIcon: prefixIcon == null
                ? null
                : maxLines != null && maxLines! > 1
                    ? Padding(
                        padding: EdgeInsets.only(
                          bottom: (maxLines! - 1) * 22.0, 
                        ),
                        child: Icon(prefixIcon),
                      )
                    : Icon(prefixIcon),
          ),
        ),
      ],
    );
  }
}
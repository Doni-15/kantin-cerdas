import 'package:flutter/material.dart';

class KcSearchField extends StatelessWidget {
  const KcSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.maxLength,
    this.hideCounter = false,
    this.onChanged,
    this.onSubmitted,
    this.showClearButton = false,
    this.onClear,
    this.clearTooltip = 'Bersihkan pencarian',
    this.clearIcon = Icons.clear,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final int? maxLength;
  final bool hideCounter;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showClearButton;
  final VoidCallback? onClear;
  final String clearTooltip;
  final IconData clearIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLength: maxLength,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        counterText: hideCounter ? '' : null,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: showClearButton && onClear != null
            ? IconButton(
                tooltip: clearTooltip,
                onPressed: onClear,
                icon: Icon(clearIcon),
              )
            : null,
      ),
    );
  }
}

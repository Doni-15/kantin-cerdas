import 'package:flutter/material.dart';

enum KcButtonVariant {
  filled,
  outlined,
}

class KcButton extends StatelessWidget {
  const KcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KcButtonVariant.filled,
    this.leading,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KcButtonVariant variant;
  final Widget? leading;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(label),
          ],
        );

    return SizedBox(
      width: double.infinity,
      child: switch (variant) {
        KcButtonVariant.filled => FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
        KcButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      },
    );
  }
}
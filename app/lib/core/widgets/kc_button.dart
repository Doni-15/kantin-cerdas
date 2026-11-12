import 'package:flutter/material.dart';

import 'package:kantin_cerdas/theme/kc_spacing.dart';

enum KcButtonVariant { filled, outlined }

class KcButton extends StatelessWidget {
  const KcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KcButtonVariant.filled,
    this.leading,
    this.isLoading = false,
    this.fullWidth = true,
  });

  static const _progressSize = 20.0;
  static const _progressStrokeWidth = 2.0;

  final String label;
  final VoidCallback? onPressed;
  final KcButtonVariant variant;
  final Widget? leading;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final leadingWidget = leading;
    final callback = isLoading ? null : onPressed;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingWidget != null) ...[
          leadingWidget,
          const SizedBox(width: KcSpacing.xs),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );

    final child = Stack(
      alignment: Alignment.center,
      children: [
        // Pertahankan ukuran konten selama indikator ditampilkan.
        Opacity(opacity: isLoading ? 0 : 1, child: content),
        SizedBox.square(
          dimension: _progressSize,
          child: isLoading
              ? CircularProgressIndicator(
                  strokeWidth: _progressStrokeWidth,
                  semanticsLabel: '$label, sedang diproses',
                )
              : null,
        ),
      ],
    );

    final button = switch (variant) {
      KcButtonVariant.filled => FilledButton(onPressed: callback, child: child),
      KcButtonVariant.outlined => OutlinedButton(
        onPressed: callback,
        child: child,
      ),
    };

    return Semantics(
      liveRegion: isLoading,
      child: SizedBox(width: fullWidth ? double.infinity : null, child: button),
    );
  }
}

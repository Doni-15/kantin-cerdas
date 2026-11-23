import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class KcStatusBadge extends StatelessWidget {
  const KcStatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.showDot = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: KcSpacing.xs,
      vertical: 4,
    ),
    this.textStyle,
  });

  final String label;
  final Color foreground;
  final Color background;
  final bool showDot;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        textStyle ??
        Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KcRadius.small),
      ),
      child: Padding(
        padding: padding,
        child: showDot
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: foreground,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(child: Text(label, style: effectiveStyle)),
                ],
              )
            : Text(label, style: effectiveStyle),
      ),
    );
  }
}

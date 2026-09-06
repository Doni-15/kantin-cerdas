import 'package:flutter/material.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_motion.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_size.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_spacing.dart';

enum KcButtonVariant { primary, secondary, tertiary, destructive }

/// Tinggi minimum, bukan tinggi tetap: label tetap dapat membungkus.
class KcButton extends StatelessWidget {
  const KcButton({
    required this.label,
    required this.onPressed,
    this.variant = KcButtonVariant.primary,
    this.loading = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final KcButtonVariant variant;
  final bool loading;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final destructive = variant == KcButtonVariant.destructive;
    final filled = destructive || variant == KcButtonVariant.primary;
    // Menggelapkan tombol terang (atau mencerahkan tombol pada tema gelap)
    // menjaga kontras label ketika ditekan dan difokuskan.
    final overlay = filled ? colors.onSurface : colors.surface;
    final style = ButtonStyle(
      animationDuration: KantinCerdasMotion.durationOf(context),
      minimumSize: const WidgetStatePropertyAll(
        Size(
          KantinCerdasSize.minimumTouchTarget,
          KantinCerdasSize.minimumTouchTarget,
        ),
      ),
      tapTargetSize: MaterialTapTargetSize.padded,
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: colors.onSurface, width: 2);
        }
        if (variant == KcButtonVariant.secondary) {
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? colors.outlineVariant
                : colors.primary,
          );
        }
        return BorderSide.none;
      }),
      foregroundColor: destructive
          ? WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.disabled)
                  ? Theme.of(context).disabledColor
                  : colors.onError;
            })
          : null,
      backgroundColor: destructive
          ? WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.disabled)
                  ? colors.surfaceContainerHighest
                  : colors.error;
            })
          : null,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return Colors.transparent;
        if (states.contains(WidgetState.focused)) {
          return overlay.withValues(alpha: 0.16);
        }
        if (states.contains(WidgetState.pressed)) {
          return overlay.withValues(alpha: 0.12);
        }
        return null;
      }),
    );
    final child = loading
        ? Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KantinCerdasSpacing.space2,
            children: [
              SizedBox.square(
                dimension: 20,
                child: ExcludeSemantics(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: MediaQuery.disableAnimationsOf(context)
                        ? 0.75
                        : null,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text('$label — Memproses', textAlign: TextAlign.center),
            ],
          )
        : Text(label, textAlign: TextAlign.center);
    final callback = loading ? null : onPressed;
    final Widget button;
    switch (variant) {
      case KcButtonVariant.primary:
      case KcButtonVariant.destructive:
        button = FilledButton(
          onPressed: callback,
          focusNode: focusNode,
          autofocus: autofocus,
          style: style,
          child: child,
        );
      case KcButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: callback,
          focusNode: focusNode,
          autofocus: autofocus,
          style: style,
          child: child,
        );
      case KcButtonVariant.tertiary:
        button = TextButton(
          onPressed: callback,
          focusNode: focusNode,
          autofocus: autofocus,
          style: style,
          child: child,
        );
    }
    return Semantics(liveRegion: loading, child: button);
  }
}

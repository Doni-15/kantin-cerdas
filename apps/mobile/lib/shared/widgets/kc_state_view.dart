import 'package:flutter/material.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_colors.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_radius.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_spacing.dart';
import 'package:kantincerdas/shared/widgets/kc_button.dart';

enum KcViewState { loading, empty, error, offline, disabled, success }

/// State presentasi saja. Data, retry, dan keputusan bisnis milik pemanggil.
/// Sertakan child untuk mempertahankan konten tersimpan pada kondisi offline.
class KcStateView extends StatelessWidget {
  const KcStateView({
    required this.state,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.child,
    super.key,
  }) : assert((actionLabel == null) == (onAction == null));

  final KcViewState state;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = switch (state) {
      KcViewState.loading => Icons.hourglass_top_rounded,
      KcViewState.empty => Icons.search_off_rounded,
      KcViewState.error => Icons.error_outline_rounded,
      KcViewState.offline => Icons.wifi_off_rounded,
      KcViewState.disabled => Icons.info_outline_rounded,
      KcViewState.success => Icons.check_circle_outline_rounded,
    };
    final foreground = switch (state) {
      KcViewState.error => colors.onErrorContainer,
      KcViewState.success => KantinCerdasColors.available,
      _ => colors.onSurface,
    };
    final background = switch (state) {
      KcViewState.error => colors.errorContainer,
      KcViewState.success => KantinCerdasColors.availableContainer,
      _ => colors.surfaceContainerLow,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Container(
            color: background,
            padding: const EdgeInsets.all(KantinCerdasSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(height: KantinCerdasSpacing.space2),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: foreground,
                  ),
                ),
                const SizedBox(height: KantinCerdasSpacing.space2),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
                if (onAction != null) ...[
                  const SizedBox(height: KantinCerdasSpacing.space3),
                  KcButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    variant: KcButtonVariant.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (state == KcViewState.loading) ...[
          const SizedBox(height: KantinCerdasSpacing.space3),
          const KcSkeleton(),
        ],
        if (child != null) ...[
          const SizedBox(height: KantinCerdasSpacing.space3),
          child!,
        ],
      ],
    );
  }
}

/// Placeholder statis; tidak memakai shimmer atau ticker berulang.
class KcSkeleton extends StatelessWidget {
  const KcSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final width in [1.0, 0.7, 0.45])
            FractionallySizedBox(
              widthFactor: width,
              child: Container(
                height: KantinCerdasSpacing.space4,
                margin: const EdgeInsets.only(
                  bottom: KantinCerdasSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(KantinCerdasRadius.small),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

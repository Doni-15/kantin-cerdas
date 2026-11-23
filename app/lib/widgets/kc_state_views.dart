import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class KcLoadingView extends StatelessWidget {
  const KcLoadingView({super.key, this.message = 'Memuat data…'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KcSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: KcSpacing.sm),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class KcErrorView extends StatelessWidget {
  const KcErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.fallback = 'Gagal memuat data.',
    this.retryLabel = 'Coba Lagi',
    this.messageStyle,
    this.useTonalButton = false,
    this.scrollable = true,
  });

  final Object? error;
  final VoidCallback onRetry;
  final String fallback;
  final String retryLabel;
  final TextStyle? messageStyle;
  final bool useTonalButton;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(KcSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
          const SizedBox(height: KcSpacing.sm),
          Text(
            presentAppError(error, fallback: fallback),
            textAlign: TextAlign.center,
            style: messageStyle ?? theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: KcSpacing.md),
          if (useTonalButton)
            FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel))
          else
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
        ],
      ),
    );
    return Center(
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}

class KcEmptyView extends StatelessWidget {
  const KcEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 44,
    this.subtitleSpacing = KcSpacing.xs,
    this.subtitleStyle,
    this.scrollable = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double iconSize;
  final double subtitleSpacing;
  final TextStyle? subtitleStyle;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(KcSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: KcSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: subtitleSpacing),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style:
                  subtitleStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: KcSpacing.md),
            action!,
          ],
        ],
      ),
    );
    return Center(
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}

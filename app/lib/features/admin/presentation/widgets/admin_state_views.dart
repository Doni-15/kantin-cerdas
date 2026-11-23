import 'package:flutter/material.dart';
import 'package:kantin_cerdas/widgets/kc_state_views.dart';

class AdminErrorView extends StatelessWidget {
  const AdminErrorView({
    super.key,
    required this.error,
    required this.fallback,
    required this.onRetry,
  });

  final Object error;
  final String fallback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      KcErrorView(error: error, fallback: fallback, onRetry: onRetry);
}

class AdminEmptyView extends StatelessWidget {
  const AdminEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KcEmptyView(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconSize: 42,
      subtitleSpacing: 6,
      subtitleStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

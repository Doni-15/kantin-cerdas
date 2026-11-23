import 'package:flutter/material.dart';
import 'package:kantin_cerdas/widgets/kc_state_views.dart';

class OwnerLoadingView extends StatelessWidget {
  const OwnerLoadingView({super.key, this.message = 'Memuat data…'});

  final String message;

  @override
  Widget build(BuildContext context) => KcLoadingView(message: message);
}

class OwnerErrorView extends StatelessWidget {
  const OwnerErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.fallback = 'Data belum dapat dimuat. Coba lagi.',
  });

  final Object? error;
  final VoidCallback onRetry;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KcErrorView(
      error: error,
      onRetry: onRetry,
      fallback: fallback,
      retryLabel: 'Coba lagi',
      messageStyle: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.error,
      ),
      useTonalButton: true,
      scrollable: false,
    );
  }
}

class OwnerEmptyView extends StatelessWidget {
  const OwnerEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => KcEmptyView(
    icon: icon,
    title: title,
    subtitle: description,
    action: action,
    scrollable: false,
  );
}

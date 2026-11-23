import 'package:flutter/material.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';
import 'package:kantin_cerdas/widgets/kc_state_views.dart';

export 'package:kantin_cerdas/core/utils/kc_formatters.dart';

void showCustomerSnackBar(BuildContext context, String message) =>
    showKcSnackBar(context, message);

Future<bool> showCustomerConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
}) => showKcConfirmDialog(
  context,
  title: title,
  message: message,
  confirmLabel: confirmLabel,
  cancelLabel: cancelLabel,
  destructive: destructive,
);

class CustomerErrorView extends StatelessWidget {
  const CustomerErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.fallback = 'Gagal memuat data.',
  });

  final Object? error;
  final VoidCallback onRetry;
  final String fallback;

  @override
  Widget build(BuildContext context) =>
      KcErrorView(error: error, onRetry: onRetry, fallback: fallback);
}

class CustomerEmptyView extends StatelessWidget {
  const CustomerEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      KcEmptyView(icon: icon, title: title, subtitle: subtitle, action: action);
}

import 'package:flutter/material.dart';

abstract final class KcSnackBar {
  static void success(BuildContext context, String message) {
    _show(context, message, label: 'Berhasil');
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      label: 'Terjadi kesalahan',
      duration: const Duration(seconds: 6),
    );
  }

  static void info(BuildContext context, String message) {
    _show(context, message, label: 'Informasi');
  }

  static void _show(
    BuildContext context,
    String message, {
    required String label,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('$label: $message'),
          duration: duration,
          showCloseIcon: true,
        ),
      );
  }
}

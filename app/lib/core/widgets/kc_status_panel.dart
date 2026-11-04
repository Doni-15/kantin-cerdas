import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Pesan keadaan bersama. Teks dan aksi ditentukan oleh fitur pemanggil.
class KcStatusPanel extends StatelessWidget {
  const KcStatusPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.loading = false,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: loading
                    ? CircularProgressIndicator(semanticsLabel: title)
                    : Icon(icon, size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: KcSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: KcSpacing.xs),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: KcSpacing.md),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

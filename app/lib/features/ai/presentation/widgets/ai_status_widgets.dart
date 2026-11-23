import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/ai/domain/ai_models.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_status_badge.dart';

class AiQuotaHeaderBadge extends StatelessWidget {
  const AiQuotaHeaderBadge({super.key, required this.status});

  final AiStatusSnapshot status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = status.providerReady
        ? 'AI ${status.quota.remainingToday}/${status.quota.dailyLimit} WIB'
        : 'Mode Katalog';
    return KcStatusBadge(
      label: label,
      foreground: theme.colorScheme.onSecondaryContainer,
      background: theme.colorScheme.secondaryContainer,
      textStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class AiFallbackBanner extends StatelessWidget {
  const AiFallbackBanner({super.key, required this.status});

  final AiStatusSnapshot status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (status.providerReady && !status.fallbackActive) {
      return const SizedBox.shrink();
    }
    final quotaZero = status.quota.remainingToday <= 0;
    final message = quotaZero
        ? 'Kuota harian AI habis (reset 00:00 WIB). Pencarian katalog tetap aktif tanpa mengurangi kuota.'
        : 'Asisten AI eksternal belum aktif — pencarian & rekomendasi katalog nyata tetap aktif tanpa memakai kuota.';

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: KcSpacing.md,
        vertical: KcSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: KcSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiErrorBanner extends StatelessWidget {
  const AiErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KcSpacing.md,
        KcSpacing.xs,
        KcSpacing.md,
        0,
      ),
      child: Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(KcRadius.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KcSpacing.sm,
            vertical: KcSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: KcSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: theme.colorScheme.onErrorContainer,
                onPressed: onDismiss,
                tooltip: 'Tutup pesan galat',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

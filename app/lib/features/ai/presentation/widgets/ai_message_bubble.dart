import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/kc_formatters.dart';
import 'package:kantin_cerdas/features/ai/domain/ai_models.dart';
import 'package:kantin_cerdas/features/ai/presentation/widgets/ai_recommendation_card.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_inline_progress_indicator.dart';

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.accountId,
    required this.message,
    this.onOrderCompleted,
  });

  final String accountId;
  final AiChatMessage message;
  final ValueChanged<String>? onOrderCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: KcSpacing.sm, left: 48),
          padding: const EdgeInsets.all(KcSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(KcRadius.card),
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: KcSpacing.md, right: 24),
        padding: const EdgeInsets.all(KcSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(KcRadius.card),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: KcSpacing.xs,
              runSpacing: 4,
              children: [
                if (message.isGeneralCulinary)
                  const _InfoTag(label: 'Kuliner Umum (Bukan Katalog)')
                else if (message.fallbackUsed)
                  const _InfoTag(label: 'Katalog Terverifikasi (Fallback)')
                else
                  const _InfoTag(label: 'Food Assistant'),
                if (message.appliedMaxBudget != null)
                  _InfoTag(
                    label: 'Maks ${formatRupiah(message.appliedMaxBudget!)}',
                  ),
              ],
            ),
            const SizedBox(height: KcSpacing.xs),
            Text(message.text, style: theme.textTheme.bodyMedium),
            if (message.recommendations.isNotEmpty) ...[
              const SizedBox(height: KcSpacing.xs),
              for (final rec in message.recommendations)
                AiRecommendationCard(
                  accountId: accountId,
                  item: rec,
                  onOrderCompleted: onOrderCompleted,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(KcRadius.small),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class AiTypingIndicatorBubble extends StatelessWidget {
  const AiTypingIndicatorBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: KcSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: KcSpacing.sm,
          vertical: KcSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(KcRadius.card),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KcInlineProgressIndicator(size: 14),
            const SizedBox(width: KcSpacing.xs),
            Text('Memproses rekomendasi...', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

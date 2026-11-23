import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/ai/domain/ai_models.dart';
import 'package:kantin_cerdas/features/ai/presentation/widgets/ai_quick_prompts.dart';
import 'package:kantin_cerdas/features/ai/presentation/widgets/ai_status_widgets.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AiEmptyConversationView extends StatelessWidget {
  const AiEmptyConversationView({
    super.key,
    required this.status,
    required this.onSelectPrompt,
    required this.onOpenSearch,
  });

  final AiStatusSnapshot? status;
  final ValueChanged<String> onSelectPrompt;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KcSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null) ...[
            AiFallbackBanner(status: status!),
            const SizedBox(height: KcSpacing.md),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: KcSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo! Mau cari makanan apa hari ini?',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Rekomendasi menu memakai data katalog kantin nyata dengan tombol Lihat Detail. Pemesanan tetap dilakukan langsung oleh Anda.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KcSpacing.md),
          Text('Contoh pertanyaan cepat', style: theme.textTheme.labelLarge),
          const SizedBox(height: KcSpacing.xs),
          Wrap(
            spacing: KcSpacing.xs,
            runSpacing: KcSpacing.xs,
            children: [
              for (final p in aiQuickPrompts)
                ActionChip(
                  label: Text(p.label),
                  onPressed: () => onSelectPrompt(p.message),
                ),
            ],
          ),
          const SizedBox(height: KcSpacing.md),
          OutlinedButton.icon(
            onPressed: onOpenSearch,
            icon: const Icon(Icons.search),
            label: const Text('Buka Pencarian Kantin & Menu'),
          ),
        ],
      ),
    );
  }
}

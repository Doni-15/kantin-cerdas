import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

const aiQuickPrompts = <({String label, String message})>[
  (label: 'Menu ≤ Rp20.000', message: 'Rekomendasi makanan maksimal Rp20.000'),
  (
    label: 'Minuman segar',
    message: 'Carikan minuman segar dari kantin yang buka',
  ),
  (
    label: 'Info tutup / habis',
    message: 'Ada menu yang sedang habis atau kantin tutup?',
  ),
  (
    label: 'Ide resep ayam',
    message: 'Beri ide resep ayam sederhana untuk makan siang',
  ),
];

class AiQuickPromptStrip extends StatelessWidget {
  const AiQuickPromptStrip({
    super.key,
    required this.disabled,
    required this.onSelectPrompt,
  });

  final bool disabled;
  final ValueChanged<String> onSelectPrompt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: KcSpacing.md,
        vertical: 4,
      ),
      child: Row(
        children: [
          for (var i = 0; i < aiQuickPrompts.length; i++) ...[
            if (i > 0) const SizedBox(width: KcSpacing.xs),
            ActionChip(
              label: Text(aiQuickPrompts[i].label),
              onPressed: disabled
                  ? null
                  : () => onSelectPrompt(aiQuickPrompts[i].message),
            ),
          ],
        ],
      ),
    );
  }
}

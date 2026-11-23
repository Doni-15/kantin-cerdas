import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_inline_progress_indicator.dart';

class AiChatInputBar extends StatelessWidget {
  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(KcSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => isSending ? null : onSubmit(),
              decoration: InputDecoration(
                hintText: 'Tanya menu atau budget (mis. Rp20.000)...',
                hintMaxLines: 1,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KcRadius.control),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KcSpacing.sm,
                  vertical: KcSpacing.xs,
                ),
              ),
            ),
          ),
          const SizedBox(width: KcSpacing.xs),
          FilledButton(
            onPressed: isSending ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: isSending
                ? const KcInlineProgressIndicator()
                : const Icon(Icons.send_rounded, semanticLabel: 'Kirim'),
          ),
        ],
      ),
    );
  }
}

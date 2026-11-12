import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OrderConfirmationNotice extends StatelessWidget {
  const OrderConfirmationNotice({
    super.key,
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KcSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(KcSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (loading)
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.info_outline),
                    const SizedBox(width: KcSpacing.sm),
                    Expanded(child: Text(message)),
                  ],
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: KcSpacing.xs),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Muat ulang'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

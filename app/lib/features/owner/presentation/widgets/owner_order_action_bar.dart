import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_order_rules.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderActionBar extends StatelessWidget {
  const OwnerOrderActionBar({
    super.key,
    required this.actions,
    required this.busy,
    required this.onSelectAction,
  });

  final List<OwnerOrderAction> actions;
  final bool busy;
  final ValueChanged<OwnerOrderAction> onSelectAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: busy ? null : () => onSelectAction(actions.first),
                child: Text(actions.first.label),
              ),
              if (actions.length > 1) ...[
                const SizedBox(height: KcSpacing.xs),
                Wrap(
                  spacing: KcSpacing.xs,
                  runSpacing: KcSpacing.xs,
                  children: [
                    for (final alt in actions.skip(1))
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: alt.requiresReason
                              ? theme.colorScheme.error
                              : null,
                        ),
                        onPressed: busy ? null : () => onSelectAction(alt),
                        child: Text(alt.label),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

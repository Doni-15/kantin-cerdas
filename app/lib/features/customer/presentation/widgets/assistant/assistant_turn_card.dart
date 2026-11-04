import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_assistant_controller.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AssistantTurnCard extends StatelessWidget {
  const AssistantTurnCard({super.key, required this.turn});
  final AssistantTurn turn;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pertanyaanmu', style: theme.textTheme.labelLarge),
            Text(turn.question),
            const Divider(height: KcSpacing.lg),
            Text('Rekomendasi', style: theme.textTheme.labelLarge),
            SelectableText(turn.reply.message),
            for (final menu in turn.reply.menus) ...[
              const SizedBox(height: KcSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(menu.name),
                subtitle: Text(
                  '${menu.stallName} · ${formatRupiah(menu.price)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(Routes.customerStallLocation(menu.stallId)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

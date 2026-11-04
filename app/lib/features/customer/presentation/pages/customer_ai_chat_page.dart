import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_assistant_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_feature_message.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/assistant/assistant_composer.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/assistant/assistant_turn_card.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerAiChatPage extends ConsumerWidget {
  const CustomerAiChatPage({super.key, required this.onBackToHome});
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerAssistantControllerProvider);
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(KcSpacing.lg),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Wrap(
                spacing: KcSpacing.xs,
                runSpacing: KcSpacing.xs,
                children: [
                  TextButton.icon(
                    onPressed: onBackToHome,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Beranda'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.push(Routes.customerFoodPreferences),
                    icon: const Icon(Icons.tune),
                    label: const Text('Preferensi makanan'),
                  ),
                  if (state.turns.isNotEmpty)
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () async {
                              final controller = ref.read(
                                customerAssistantControllerProvider.notifier,
                              );
                              final clear = await showKcRoleDialog<bool>(
                                context: context,
                                ref: ref,
                                role: UserRole.customer,
                                builder: (context) => AlertDialog(
                                  scrollable: true,
                                  title: const Text('Hapus percakapan?'),
                                  content: const Text(
                                    'Percakapan di halaman ini akan dihapus.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (context.mounted && clear == true) {
                                controller.clear(expectedState: state);
                              }
                            },
                      child: const Text('Hapus percakapan'),
                    ),
                ],
              ),
              Semantics(
                header: true,
                child: Text(
                  'Asisten menu',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: KcSpacing.xs),
              const Text(
                'Sebutkan anggaran dan pilihan makananmu dalam setiap pertanyaan. '
                'Pastikan bahan dan alergi langsung kepada stan.',
              ),
              const SizedBox(height: KcSpacing.md),
              for (final turn in state.turns)
                Padding(
                  padding: const EdgeInsets.only(bottom: KcSpacing.sm),
                  child: AssistantTurnCard(turn: turn),
                ),
              if (state.pending != null)
                KcStatusPanel(
                  title: 'Menyiapkan rekomendasi',
                  message: state.pending!,
                  loading: true,
                ),
              if (state.error != null)
                KcStatusPanel(
                  title: 'Rekomendasi belum tersedia',
                  message: customerFeatureMessage(state.error!),
                  icon: Icons.info_outline,
                ),
              const SizedBox(height: KcSpacing.md),
              const AssistantComposer(),
            ],
          ),
        ),
      ),
    );
  }
}

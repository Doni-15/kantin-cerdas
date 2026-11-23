import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/ai/application/ai_providers.dart';
import 'package:kantin_cerdas/features/ai/presentation/widgets/ai_chat_input_bar.dart';
import 'package:kantin_cerdas/features/ai/presentation/widgets/ai_empty_conversation_view.dart';
import 'package:kantin_cerdas/features/ai/presentation/widgets/ai_message_bubble.dart';
import 'package:kantin_cerdas/features/ai/presentation/widgets/ai_quick_prompts.dart';
import 'package:kantin_cerdas/features/ai/presentation/widgets/ai_status_widgets.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AiFoodAssistantPage extends ConsumerStatefulWidget {
  const AiFoodAssistantPage({
    super.key,
    required this.accountId,
    required this.onOpenSearch,
    this.onOrderCompleted,
  });

  final String accountId;
  final VoidCallback onOpenSearch;
  final ValueChanged<String>? onOrderCompleted;

  @override
  ConsumerState<AiFoodAssistantPage> createState() =>
      _AiFoodAssistantPageState();
}

class _AiFoodAssistantPageState extends ConsumerState<AiFoodAssistantPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit([String? presetMessage]) async {
    final text = (presetMessage ?? _inputCtrl.text).trim();
    if (text.isEmpty) return;

    final ok = await ref
        .read(aiChatControllerProvider(widget.accountId).notifier)
        .sendMessage(text);
    if (!mounted) return;
    if (ok && presetMessage == null) {
      _inputCtrl.clear();
    }
    if (ok && _scrollCtrl.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _navigateToSearch() {
    Navigator.of(context).pop();
    widget.onOpenSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(aiChatControllerProvider(widget.accountId));
    final controller = ref.read(
      aiChatControllerProvider(widget.accountId).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: KcSpacing.xs),
            const Flexible(
              child: Text(
                'Food Assistant',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (state.status != null)
            Padding(
              padding: const EdgeInsets.only(right: KcSpacing.sm),
              child: Center(child: AiQuotaHeaderBadge(status: state.status!)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.isLoadingStatus && state.status == null)
              const LinearProgressIndicator(minHeight: 2)
            else if (state.statusLoadError != null && state.status == null)
              MaterialBanner(
                content: const Text(
                  'Gagal memeriksa status Food Assistant. Coba muat ulang.',
                ),
                actions: [
                  TextButton(
                    onPressed: controller.loadStatus,
                    child: const Text('Coba lagi'),
                  ),
                  TextButton(
                    onPressed: _navigateToSearch,
                    child: const Text('Tab Cari'),
                  ),
                ],
              ),
            Expanded(
              child: state.messages.isEmpty
                  ? AiEmptyConversationView(
                      status: state.status,
                      onSelectPrompt: (msg) => _submit(msg),
                      onOpenSearch: _navigateToSearch,
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(KcSpacing.md),
                      itemCount:
                          (state.status != null &&
                                  (!state.status!.providerReady ||
                                      state.status!.fallbackActive)
                              ? 1
                              : 0) +
                          state.messages.length +
                          (state.isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        final hasBanner =
                            state.status != null &&
                            (!state.status!.providerReady ||
                                state.status!.fallbackActive);
                        if (hasBanner && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: KcSpacing.sm,
                            ),
                            child: AiFallbackBanner(status: state.status!),
                          );
                        }
                        final msgIndex = hasBanner ? index - 1 : index;
                        if (msgIndex >= state.messages.length) {
                          return const AiTypingIndicatorBubble();
                        }
                        return AiMessageBubble(
                          accountId: widget.accountId,
                          message: state.messages[msgIndex],
                          onOrderCompleted: widget.onOrderCompleted,
                        );
                      },
                    ),
            ),
            if (state.messages.isNotEmpty)
              AiQuickPromptStrip(
                disabled: state.isSending,
                onSelectPrompt: (msg) => _submit(msg),
              ),
            if (state.errorMessage != null)
              AiErrorBanner(
                message: state.errorMessage!,
                onDismiss: controller.clearError,
              ),
            AiChatInputBar(
              controller: _inputCtrl,
              isSending: state.isSending,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

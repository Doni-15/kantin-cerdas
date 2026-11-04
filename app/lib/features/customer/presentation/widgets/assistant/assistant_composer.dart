import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_assistant_controller.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AssistantComposer extends ConsumerStatefulWidget {
  const AssistantComposer({super.key});
  @override
  ConsumerState<AssistantComposer> createState() => _AssistantComposerState();
}

class _AssistantComposerState extends ConsumerState<AssistantComposer> {
  static const _quickSuggestions = <String>[
    'Makan siang di bawah Rp20.000',
    'Yang tidak pedas dan cepat siap',
    'Ada pilihan menu berkuah?',
  ];

  final _text = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final text = _text.text;
    final ok = await ref
        .read(customerAssistantControllerProvider.notifier)
        .send(text);
    if (mounted && ok && _text.text == text) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(
      customerAssistantControllerProvider.select((s) => s.busy),
    );
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: KcSpacing.xs,
            runSpacing: KcSpacing.xs,
            children: [
              for (final suggestion in _quickSuggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: busy
                      ? null
                      : () {
                          _text.text = suggestion;
                          _text.selection = TextSelection.collapsed(
                            offset: suggestion.length,
                          );
                        },
                ),
            ],
          ),
          const SizedBox(height: KcSpacing.sm),
          TextFormField(
            controller: _text,
            enabled: !busy,
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Kebutuhan makanmu',
              hintText: 'Contoh: makan siang di bawah Rp20.000, tidak pedas',
            ),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Tulis kebutuhanmu dahulu.'
                : value!.trim().characters.length > 500
                ? 'Maksimal 500 karakter.'
                : null,
          ),
          const SizedBox(height: KcSpacing.sm),
          KcButton(
            label: 'Minta rekomendasi',
            isLoading: busy,
            onPressed: busy ? null : _send,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminUserSearchForm extends StatefulWidget {
  const AdminUserSearchForm({super.key, required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  State<AdminUserSearchForm> createState() => _AdminUserSearchFormState();
}

class _AdminUserSearchFormState extends State<AdminUserSearchForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    widget.onSearch(_controller.text.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KcTextField(
            label: 'Cari pengguna',
            hint: 'Nama atau email',
            controller: _controller,
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            validator: (value) => (value?.trim().length ?? 0) > 120
                ? 'Pencarian maksimal 120 karakter.'
                : null,
          ),
          const SizedBox(height: KcSpacing.xs),
          Wrap(
            spacing: KcSpacing.xs,
            runSpacing: KcSpacing.xs,
            children: [
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.search),
                label: const Text('Cari'),
              ),
              TextButton(
                onPressed: () {
                  _controller.clear();
                  _submit();
                },
                child: const Text('Tampilkan semua'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

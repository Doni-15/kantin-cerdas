import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_profile_service.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

enum AccountEdit { name, email, password }

class AccountEditDialog extends ConsumerStatefulWidget {
  const AccountEditDialog({
    super.key,
    required this.account,
    required this.edit,
  });

  final AuthAccount account;
  final AccountEdit edit;

  @override
  ConsumerState<AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends ConsumerState<AccountEditDialog>
    with AuthAction<AccountEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _value = TextEditingController(
    text: widget.edit == AccountEdit.name ? widget.account.displayName : null,
  );
  final _currentPassword = TextEditingController();
  final _confirmation = TextEditingController();
  String? _result;

  @override
  void dispose() {
    _value.dispose();
    _currentPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final edit = widget.edit;
    final profileService = ref.read(authProfileServiceProvider);
    await runAction(() async {
      if (edit == AccountEdit.name) {
        await profileService.updateDisplayName(
          widget.account.id,
          _value.text.trim(),
        );
        if (mounted) Navigator.pop(context);
        return;
      }
      await profileService.changeAccountCredentials(
        accountId: widget.account.id,
        currentPassword: _currentPassword.text,
        email: edit == AccountEdit.email ? _value.text.trim() : null,
        password: edit == AccountEdit.password ? _value.text : null,
      );
      if (!mounted) return;
      _currentPassword.clear();
      _value.clear();
      _confirmation.clear();
      setState(
        () => _result = edit == AccountEdit.email
            ? 'Periksa email lama dan email baru untuk menyelesaikan perubahan.'
            : 'Password berhasil diperbarui.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.edit;
    final label = switch (edit) {
      AccountEdit.name => 'Nama lengkap',
      AccountEdit.email => 'Email baru',
      AccountEdit.password => 'Password baru',
    };
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(switch (edit) {
          AccountEdit.name => 'Ubah nama',
          AccountEdit.email => 'Ubah email',
          AccountEdit.password => 'Ubah password',
        }),
        content: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (problem != null) AuthNotice(problem!),
              if (_result case final result?)
                Text(result)
              else ...[
                if (edit != AccountEdit.name) ...[
                  TextFormField(
                    controller: _currentPassword,
                    enabled: !busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Password saat ini',
                    ),
                    validator: validateAuthPassword,
                  ),
                  const SizedBox(height: KcSpacing.md),
                ],
                TextFormField(
                  controller: _value,
                  enabled: !busy,
                  keyboardType: edit == AccountEdit.email
                      ? TextInputType.emailAddress
                      : null,
                  obscureText: edit == AccountEdit.password,
                  autocorrect: edit == AccountEdit.name,
                  enableSuggestions: edit == AccountEdit.name,
                  decoration: InputDecoration(labelText: label),
                  validator: (value) => switch (edit) {
                    AccountEdit.name => validateAuthName(value),
                    AccountEdit.email => validateAuthEmail(value),
                    AccountEdit.password => validateAuthPassword(
                      value,
                      isNew: true,
                    ),
                  },
                ),
                if (edit == AccountEdit.password) ...[
                  const SizedBox(height: KcSpacing.md),
                  AuthPasswordConfirmation(
                    controller: _confirmation,
                    password: _value,
                    enabled: !busy,
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: Text(_result == null ? 'Batal' : 'Tutup'),
          ),
          if (_result == null)
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(busy ? 'Menyimpan…' : 'Simpan'),
            ),
        ],
      ),
    );
  }
}

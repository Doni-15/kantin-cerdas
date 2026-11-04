import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminUserAccessDialog extends StatefulWidget {
  const AdminUserAccessDialog({
    super.key,
    required this.name,
    required this.username,
    required this.activate,
    this.initialReason = '',
  });
  final String name;
  final String username;
  final bool activate;
  final String initialReason;
  @override
  State<AdminUserAccessDialog> createState() => _AdminUserAccessDialogState();
}

class _AdminUserAccessDialogState extends State<AdminUserAccessDialog> {
  final _form = GlobalKey<FormState>();
  late final _reason = TextEditingController(text: widget.initialReason);
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.activate ? 'Aktifkan akun?' : 'Nonaktifkan akun?'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${widget.name} (@${widget.username})'),
            const SizedBox(height: KcSpacing.md),
            Text(
              widget.activate
                  ? 'Pengguna dapat masuk kembali setelah akses diaktifkan. Peran akun tetap sama.'
                  : 'Pengguna tidak dapat mengakses layanan setelah akun dinonaktifkan. Data akun tetap disimpan.',
            ),
            const SizedBox(height: KcSpacing.md),
            KcTextField(
              label: 'Alasan perubahan akses',
              controller: _reason,
              maxLines: 4,
              maxLength: AdminUserAccessChange.maxReasonLength,
              validator: (value) => AdminUserAccessChange.validReason(value)
                  ? null
                  : 'Isi alasan perubahan, maksimal 300 karakter.',
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.of(context).pop(_reason.text.trim());
          }
        },
        child: Text(widget.activate ? 'Aktifkan' : 'Nonaktifkan'),
      ),
    ],
  );
}

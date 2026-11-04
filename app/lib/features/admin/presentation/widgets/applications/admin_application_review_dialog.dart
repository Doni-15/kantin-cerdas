import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminApplicationReviewDialog extends StatefulWidget {
  const AdminApplicationReviewDialog({
    super.key,
    required this.approve,
    required this.name,
    this.initialReason = '',
  });
  final bool approve;
  final String name;
  final String initialReason;
  @override
  State<AdminApplicationReviewDialog> createState() =>
      _AdminApplicationReviewDialogState();
}

class _AdminApplicationReviewDialogState
    extends State<AdminApplicationReviewDialog> {
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
    title: Text(widget.approve ? 'Setujui pengajuan?' : 'Tolak pengajuan?'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.name),
            const SizedBox(height: KcSpacing.md),
            if (widget.approve)
              const Text(
                'Persetujuan meminta layanan membuat stan dan memberikan akses pemilik kepada pemohon.',
              )
            else
              KcTextField(
                label: 'Alasan penolakan',
                controller: _reason,
                maxLines: 4,
                maxLength: AdminApplicationReview.maxReasonLength,
                validator: (value) => AdminApplicationReview.validReason(value)
                    ? null
                    : 'Isi alasan penolakan, maksimal 300 karakter.',
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
            Navigator.of(
              context,
            ).pop(widget.approve ? '' : _reason.text.trim());
          }
        },
        child: Text(widget.approve ? 'Setujui' : 'Tolak'),
      ),
    ],
  );
}

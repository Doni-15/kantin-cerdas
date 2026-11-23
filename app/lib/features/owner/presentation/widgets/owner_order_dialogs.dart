import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

Future<bool> showOwnerConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) => showKcConfirmDialog(
  context,
  title: title,
  message: message,
  confirmLabel: confirmLabel,
  destructive: destructive,
  scrollable: true,
);

Future<String?> showOwnerReasonSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String hint,
  required String confirmLabel,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ReasonSheetBody(
      title: title,
      description: description,
      hint: hint,
      confirmLabel: confirmLabel,
    ),
  );
}

class _ReasonSheetBody extends StatefulWidget {
  const _ReasonSheetBody({
    required this.title,
    required this.description,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String description;
  final String hint;
  final String confirmLabel;

  @override
  State<_ReasonSheetBody> createState() => _ReasonSheetBodyState();
}

class _ReasonSheetBodyState extends State<_ReasonSheetBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _controller.text.trim();
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        KcSpacing.md,
        0,
        KcSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + KcSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: KcSpacing.xs),
            Text(widget.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: KcSpacing.md),
            TextField(
              controller: _controller,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Alasan (wajib)',
                hintText: widget.hint,
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: trimmed.isEmpty
                  ? null
                  : () => Navigator.pop(context, trimmed),
              child: Text(widget.confirmLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showCompleteOrderConfirmationDialog(
  BuildContext context, {
  required String orderNumber,
  required String totalText,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) =>
        _CompleteOrderDialog(orderNumber: orderNumber, totalText: totalText),
  );
  return result ?? false;
}

class _CompleteOrderDialog extends StatefulWidget {
  const _CompleteOrderDialog({
    required this.orderNumber,
    required this.totalText,
  });

  final String orderNumber;
  final String totalText;

  @override
  State<_CompleteOrderDialog> createState() => _CompleteOrderDialogState();
}

class _CompleteOrderDialogState extends State<_CompleteOrderDialog> {
  var _cashReceived = false;
  var _foodHandedOver = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text('Selesaikan Pesanan ${widget.orderNumber}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pastikan pembayaran tunai ${widget.totalText} dan serah terima makanan telah selesai.',
          ),
          const SizedBox(height: KcSpacing.sm),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _cashReceived,
            onChanged: (v) => setState(() => _cashReceived = v ?? false),
            title: const Text('Uang tunai sudah diterima'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _foodHandedOver,
            onChanged: (v) => setState(() => _foodHandedOver = v ?? false),
            title: const Text('Makanan sudah diserahkan ke pelanggan'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: (_cashReceived && _foodHandedOver)
              ? () => Navigator.pop(context, true)
              : null,
          child: const Text('Selesaikan & Lunas'),
        ),
      ],
    );
  }
}

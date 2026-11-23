import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

void showAdminSnackBar(BuildContext context, String message) =>
    showKcSnackBar(context, message);

Future<bool> showAdminConfirmDialog(
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

Future<String?> showAdminReasonSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String fieldLabel,
  required String hint,
  required String confirmLabel,
  bool destructive = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AdminReasonSheetBody(
      title: title,
      description: description,
      fieldLabel: fieldLabel,
      hint: hint,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}

class _AdminReasonSheetBody extends StatefulWidget {
  const _AdminReasonSheetBody({
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.hint,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String description;
  final String fieldLabel;
  final String hint;
  final String confirmLabel;
  final bool destructive;

  @override
  State<_AdminReasonSheetBody> createState() => _AdminReasonSheetBodyState();
}

class _AdminReasonSheetBodyState extends State<_AdminReasonSheetBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = _controller.text.trim();
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
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            TextField(
              controller: _controller,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                hintText: widget.hint,
              ),
            ),
            const SizedBox(height: KcSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: KcSpacing.sm),
                Expanded(
                  child: FilledButton(
                    style: widget.destructive
                        ? FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          )
                        : null,
                    onPressed: trimmed.isEmpty
                        ? null
                        : () => Navigator.pop(context, trimmed),
                    child: Text(widget.confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';

Future<String?> showCustomerCartItemNoteDialog(
  BuildContext context,
  CustomerCartItem item,
) async {
  final ctrl = TextEditingController(text: item.itemNote);
  final updatedNote = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Catatan: ${item.menuName}'),
      content: TextField(
        controller: ctrl,
        maxLength: 300,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Kosongkan bila tidak ada catatan',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return updatedNote;
}

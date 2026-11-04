import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_session_dialog.dart';

Future<bool> confirmOwnerDiscard(BuildContext context, WidgetRef ref) async {
  final result = await showOwnerDialog<bool>(
    context: context,
    ref: ref,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: const Text('Buang perubahan?'),
      content: const Text('Isian yang belum disimpan akan hilang.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Lanjut mengedit'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Buang perubahan'),
        ),
      ],
    ),
  );
  return result == true;
}

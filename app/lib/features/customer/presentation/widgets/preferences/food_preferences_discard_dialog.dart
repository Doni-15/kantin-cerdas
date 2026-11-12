import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

Future<bool> confirmFoodPreferencesDiscard(
  BuildContext context,
  WidgetRef ref, {
  required bool reload,
}) async {
  final discard = await showKcRoleDialog<bool>(
    context: context,
    ref: ref,
    role: UserRole.customer,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: Text(reload ? 'Muat ulang preferensi?' : 'Tinggalkan isian?'),
      content: Text(
        reload
            ? 'Isian yang belum disimpan akan diganti dengan data terbaru dari layanan.'
            : 'Perubahan yang belum disimpan akan hilang.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Lanjut mengisi'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(reload ? 'Muat ulang' : 'Tinggalkan isian'),
        ),
      ],
    ),
  );
  return discard == true;
}

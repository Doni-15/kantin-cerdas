import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

Future<bool> confirmApplicationDiscard(
  BuildContext context,
  WidgetRef ref,
) async {
  final session = ref.read(authStateProvider.notifier);
  final generation = session.sessionGeneration;
  final actor = ref.read(authStateProvider).asData?.value?.id;
  bool current(WidgetRef currentRef) {
    final auth = currentRef.read(authStateProvider);
    final user = auth.asData?.value;
    final notifier = currentRef.read(authStateProvider.notifier);
    return !auth.isLoading &&
        !auth.hasError &&
        user != null &&
        user.isActive &&
        user.role.canUseCustomerFeatures &&
        user.id == actor &&
        identical(session, notifier) &&
        notifier.sessionGeneration == generation;
  }

  if (!current(ref)) {
    return false;
  }
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Consumer(
      builder: (dialogContext, dialogRef, _) {
        dialogRef.watch(authStateProvider);
        dialogRef.watch(authStateProvider.notifier);
        if (!current(dialogRef)) {
          final route = ModalRoute.of(dialogContext);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (route != null && route.isActive) {
              route.navigator?.removeRoute(route);
            }
          });
          return const SizedBox.shrink();
        }
        return AlertDialog(
          scrollable: true,
          title: const Text('Tinggalkan isian?'),
          content: const Text(
            'Isian yang belum dikirim akan hilang. Pengajuan yang sudah dikirim tetap dapat diperiksa hasilnya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Lanjut mengisi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tinggalkan isian'),
            ),
          ],
        );
      },
    ),
  );
  return context.mounted && current(ref) && result == true;
}

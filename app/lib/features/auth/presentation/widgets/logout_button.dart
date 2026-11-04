import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_confirm_dialog.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/logout_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';

/// Tombol logout yang dapat digunakan oleh semua role.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key, this.confirmBeforeLogout = true});

  final bool confirmBeforeLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(logoutControllerProvider, (previous, next) {
      if (!context.mounted || previous?.isLoading != true) {
        return;
      }

      if (next case AsyncError<void>(:final error)) {
        KcSnackBar.error(context, authErrorMessage(error));
      }
    });

    final isLoading = ref.watch(logoutControllerProvider).isLoading;

    return KcButton(
      label: 'Keluar dari akun',
      variant: KcButtonVariant.outlined,
      leading: const Icon(Icons.logout_rounded),
      isLoading: isLoading,
      onPressed: () async {
        if (confirmBeforeLogout) {
          final confirmed = await KcConfirmDialog.show(
            context: context,
            title: 'Keluar dari akun?',
            message: 'Apakah kamu yakin ingin keluar dari akun?',
            confirmLabel: 'Keluar',
            cancelLabel: 'Batal',
            isDestructive: true,
          );
          if (!confirmed || !context.mounted) {
            return;
          }
        }
        await ref.read(logoutControllerProvider.notifier).submit();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
<<<<<<< HEAD
=======
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_logout_button.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
>>>>>>> origin/rio/kantin-cerdas

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

<<<<<<< HEAD
      if (next case AsyncError<void>(:final error)) {
        KcSnackBar.error(context, authErrorMessage(error));
      }
=======
class _LogoutButtonState extends ConsumerState<LogoutButton> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    // Cegah tekan berulang selama proses berjalan.
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
>>>>>>> origin/rio/kantin-cerdas
    });

    final isLoading = ref.watch(logoutControllerProvider).isLoading;

<<<<<<< HEAD
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
=======
      // Router baru berpindah ke login pada frame berikutnya, jadi widget ini
      // masih terpasang. Snackbar berada di overlay sehingga tetap tampil
      // di halaman login.
      if (!mounted) {
        return;
      }

      KcSnackBar.success(context, 'Berhasil keluar dari akun.');
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoggingOut = false;
      });

      KcSnackBar.error(context, 'Gagal keluar dari akun. Silakan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return KcProfileLogoutButton(
      onPressed: _handleLogout,
      isLoading: _isLoggingOut,
>>>>>>> origin/rio/kantin-cerdas
    );
  }
}

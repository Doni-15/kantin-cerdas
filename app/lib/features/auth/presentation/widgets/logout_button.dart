import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';
import 'package:kantin_cerdas/core/widgets/profile/kc_profile_logout_button.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

/// Tombol keluar untuk semua role.
///
/// Alur: tombol loading -> sesi dihapus (token + auth state) -> snackbar.
/// Router mengarahkan ke halaman login karena auth state menjadi null.
class LogoutButton extends ConsumerStatefulWidget {
  const LogoutButton({super.key});

  @override
  ConsumerState<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends ConsumerState<LogoutButton> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    // Cegah tekan berulang selama proses berjalan.
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref.read(authStateProvider.notifier).logout();

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
    );
  }
}

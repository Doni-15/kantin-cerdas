import 'package:flutter/material.dart';

class KcProfileLogoutButton extends StatelessWidget {
  const KcProfileLogoutButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;

  /// Saat true, tombol dinonaktifkan dan menampilkan indikator loading.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Menggunakan OutlinedButton penuh (Full Width) agar lebih tegas dan profesional
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.error,
              ),
            )
          : const Icon(Icons.logout_rounded),
      label: const Text('Keluar dari Akun'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.error,
        side: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.5),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size.fromHeight(54), // Memaksa tombol membentang penuh
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

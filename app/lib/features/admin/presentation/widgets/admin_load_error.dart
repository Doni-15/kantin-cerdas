import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';

class AdminLoadError extends StatelessWidget {
  const AdminLoadError({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error is AdminNotConfiguredFailure) {
      return const KcStatusPanel(
        title: 'Layanan admin belum tersedia',
        message: 'Data belum dapat ditampilkan saat ini.',
        icon: Icons.cloud_off_outlined,
      );
    }
    if (error is AdminAccessFailure) {
      return const KcStatusPanel(
        title: 'Akses admin diperlukan',
        message: 'Masuk dengan akun admin yang aktif untuk membuka data ini.',
        icon: Icons.lock_outline,
      );
    }
    return KcStatusPanel(
      title: 'Data belum dapat dimuat',
      message: error is AdminInvalidDataFailure
          ? 'Data layanan tidak valid. Muat ulang atau hubungi pengelola.'
          : error is AdminReadTimeoutFailure
          ? 'Waktu pembacaan habis. Periksa koneksi lalu coba lagi.'
          : 'Periksa koneksi lalu coba lagi.',
      icon: Icons.cloud_off_outlined,
      action: KcButton(label: 'Coba lagi', onPressed: onRetry),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_order_detail_failure.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_load_error.dart';

class OwnerOrderDetailError extends StatelessWidget {
  const OwnerOrderDetailError({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    if (failure is! OwnerOrderDetailFailure) {
      return OwnerLoadError(error: failure, onRetry: onRetry);
    }
    final message = switch (failure) {
      OwnerOrderDetailInvalidReferenceFailure() =>
        'Referensi pesanan tidak valid. Buka kembali pesanan dari daftar.',
      OwnerOrderDetailInvalidDataFailure() =>
        'Rincian dan status pembayaran belum dapat dipastikan. Muat ulang sebelum mengambil tindakan.',
      OwnerOrderDetailTimeoutFailure() =>
        'Pembacaan pesanan terlalu lama. Periksa koneksi lalu coba lagi.',
    };
    return KcStatusPanel(
      title: 'Detail pesanan belum tersedia',
      message: message,
      icon: Icons.receipt_long_outlined,
      action: failure is OwnerOrderDetailInvalidReferenceFailure
          ? null
          : OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
    );
  }
}

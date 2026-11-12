import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_detail_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_feature_error.dart';

class CustomerOrderDetailError extends StatelessWidget {
  const CustomerOrderDetailError({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    if (failure is CustomerOrderDetailFailure) {
      final invalid = failure is CustomerOrderDetailInvalidReferenceFailure;
      return KcStatusPanel(
        title: invalid
            ? 'Referensi pesanan tidak valid'
            : 'Detail belum dapat dimuat',
        message: switch (failure) {
          CustomerOrderDetailInvalidReferenceFailure() =>
            'Buka pesanan dari daftar pesanan atau riwayat.',
          CustomerOrderDetailInvalidDataFailure() =>
            'Rincian yang diterima tidak sesuai dengan pesanan ini. Coba muat ulang.',
          CustomerOrderDetailTimeoutFailure() =>
            'Pembacaan melewati batas waktu. Periksa koneksi lalu coba lagi.',
        },
        icon: Icons.info_outline,
        action: invalid
            ? null
            : KcButton(label: 'Coba lagi', onPressed: onRetry),
      );
    }
    if (failure is CustomerFeatureForbiddenFailure) {
      return const KcStatusPanel(
        title: 'Pesanan tidak dapat diakses',
        message: 'Detail hanya tersedia untuk akun pemilik pesanan.',
        icon: Icons.lock_outline,
      );
    }
    return CustomerFeatureError(error: error, onRetry: onRetry);
  }
}

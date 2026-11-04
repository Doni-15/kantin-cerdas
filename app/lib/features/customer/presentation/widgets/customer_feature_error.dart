import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_feature_message.dart';

class CustomerFeatureError extends StatelessWidget {
  const CustomerFeatureError({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final unavailable = error is CustomerFeatureNotConfiguredFailure;
    return KcStatusPanel(
      title: unavailable ? 'Layanan belum tersedia' : 'Belum dapat memuat data',
      message: customerFeatureMessage(error),
      icon: Icons.cloud_off_outlined,
      action: unavailable
          ? null
          : KcButton(label: 'Coba lagi', onPressed: onRetry),
    );
  }
}

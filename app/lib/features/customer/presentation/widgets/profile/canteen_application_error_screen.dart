import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/canteen_application_error_message.dart';

class CanteenApplicationErrorScreen extends ConsumerWidget {
  const CanteenApplicationErrorScreen({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buka Kantin'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                canteenApplicationErrorMessage(error),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              KcButton(
                label: 'Coba Lagi',
                onPressed: () => ref.invalidate(canteenApplicationProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

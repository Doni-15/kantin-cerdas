import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerProfileOwnerApplicationCard extends ConsumerWidget {
  const CustomerProfileOwnerApplicationCard({
    super.key,
    required this.accountId,
    required this.onOpenForm,
  });

  final String accountId;
  final VoidCallback onOpenForm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stateAsync = ref.watch(customerOwnerApplicationProvider(accountId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: stateAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Pengajuan Owner',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                presentAppError(error, fallback: 'Gagal memeriksa status.'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(customerOwnerApplicationProvider(accountId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
          data: (state) {
            final app = state.latestApplication;
            if (app == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Punya kantin?', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Ajukan akun menjadi Pemilik Kantin untuk mengelola kantin dan menu Anda sendiri.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: KcSpacing.sm),
                  FilledButton.tonal(
                    onPressed: onOpenForm,
                    child: const Text('Ajukan Jadi Pemilik Kantin'),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pengajuan Pemilik Kantin: ${app.status.label}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${app.plannedStallName} · ${app.plannedLocation}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (app.status == OwnerApplicationStatus.ditolak &&
                    app.rejectionReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Alasan penolakan: ${app.rejectionReason}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: KcSpacing.sm),
                OutlinedButton(
                  onPressed: onOpenForm,
                  child: Text(
                    app.status == OwnerApplicationStatus.ditolak
                        ? 'Ajukan Kembali'
                        : 'Lihat Detail Pengajuan',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

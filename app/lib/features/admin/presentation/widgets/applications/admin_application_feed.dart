import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/presentation/mappers/admin_application_labels.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_application_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_load_error.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/applications/admin_application_card.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminApplicationFeed extends ConsumerStatefulWidget {
  const AdminApplicationFeed({super.key});
  @override
  ConsumerState<AdminApplicationFeed> createState() =>
      _AdminApplicationFeedState();
}

class _AdminApplicationFeedState extends ConsumerState<AdminApplicationFeed> {
  CanteenApplicationStatus? _status = CanteenApplicationStatus.submitted;
  final _cursors = <String?>[null];
  @override
  Widget build(BuildContext context) {
    final query = (status: _status, cursor: _cursors.last);
    final provider = adminApplicationsProvider(query);
    final state = ref.watch(provider);
    return ListView(
      padding: const EdgeInsets.all(KcSpacing.lg),
      children: [
        const Text('Tinjau pengajuan usaha kantin dan berikan keputusan.'),
        const SizedBox(height: KcSpacing.md),
        Wrap(
          spacing: KcSpacing.xs,
          runSpacing: KcSpacing.xs,
          children: [
            for (final status in <CanteenApplicationStatus?>[
              null,
              ...CanteenApplicationStatus.values,
            ])
              ChoiceChip(
                label: Text(adminApplicationLabel(status)),
                selected: _status == status,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _status = status;
                      _cursors
                        ..clear()
                        ..add(null);
                    });
                  }
                },
              ),
          ],
        ),
        if (state.error is! AdminNotConfiguredFailure)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref.invalidate(provider),
              icon: const Icon(Icons.refresh),
              label: const Text('Muat ulang'),
            ),
          ),
        const SizedBox(height: KcSpacing.md),
        state.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const KcLoadingSkeleton(
            label: 'Memuat pengajuan',
            layout: KcSkeletonLayout.list,
          ),
          error: (error, _) => AdminLoadError(
            error: error,
            onRetry: () => ref.invalidate(provider),
          ),
          data: (page) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (page.items.isEmpty)
                const KcStatusPanel(
                  title: 'Tidak ada pengajuan',
                  message: 'Belum ada pengajuan pada filter ini.',
                ),
              for (final application in page.items)
                AdminApplicationCard(application: application),
              if (page.nextCursor != null && _cursors.contains(page.nextCursor))
                const KcStatusPanel(
                  title: 'Halaman berikutnya tidak tersedia',
                  message:
                      'Urutan data berubah. Pilih ulang filter untuk memuat dari awal.',
                ),
              const SizedBox(height: KcSpacing.md),
              Wrap(
                spacing: KcSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: _cursors.length <= 1
                        ? null
                        : () => setState(() => _cursors.removeLast()),
                    child: const Text('Sebelumnya'),
                  ),
                  OutlinedButton(
                    onPressed:
                        page.nextCursor == null ||
                            _cursors.contains(page.nextCursor)
                        ? null
                        : () => setState(() => _cursors.add(page.nextCursor)),
                    child: const Text('Berikutnya'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

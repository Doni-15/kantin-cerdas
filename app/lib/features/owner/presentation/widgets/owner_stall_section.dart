import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_load_error.dart';

class OwnerStallSection extends ConsumerWidget {
  const OwnerStallSection({super.key, required this.builder});
  final Widget Function(OwnerStall) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(ownerStallProvider)
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const KcLoadingSkeleton(
            label: 'Memuat stan',
            layout: KcSkeletonLayout.detail,
          ),
          error: (error, _) => OwnerLoadError(
            error: error,
            onRetry: () => ref.invalidate(ownerStallProvider),
          ),
          data: (stall) => stall == null
              ? KcStatusPanel(
                  title: 'Stan belum terhubung',
                  message:
                      'Hubungi admin kampus jika pengajuanmu sudah disetujui.',
                  icon: Icons.storefront_outlined,
                  action: OutlinedButton(
                    onPressed: () => ref.invalidate(ownerStallProvider),
                    child: const Text('Periksa lagi'),
                  ),
                )
              : builder(stall),
        );
  }
}

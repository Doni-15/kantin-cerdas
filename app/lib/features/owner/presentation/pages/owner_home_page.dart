import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/application/owner_stall_controller.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_order_detail_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_active_counts_card.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_attention_order_tile.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_dashboard_stall_cards.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_dialogs.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

class OwnerHomePage extends ConsumerStatefulWidget {
  const OwnerHomePage({
    super.key,
    required this.session,
    required this.onOpenAccount,
    required this.onOpenStallTab,
    required this.onOpenOrdersTab,
  });

  final AuthSession session;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenStallTab;
  final ValueChanged<OwnerOrderStatus?> onOpenOrdersTab;

  @override
  ConsumerState<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends ConsumerState<OwnerHomePage> {
  var _togglingOpen = false;

  Future<void> _toggleOpen(OwnerStall stall) async {
    if (_togglingOpen) return;
    final nextOpen = !stall.isOpen;
    final confirmed = await showOwnerConfirmDialog(
      context,
      title: nextOpen ? 'Buka kantin sekarang?' : 'Tutup kantin sementara?',
      message: nextOpen
          ? 'Pelanggan dapat melihat kantin dan mengirim pesanan baru.'
          : 'Pesanan baru akan dihentikan. Pesanan yang sudah aktif tetap harus diproses.',
      confirmLabel: nextOpen ? 'Buka Kantin' : 'Tutup Kantin',
    );
    if (!mounted || !confirmed) return;
    setState(() => _togglingOpen = true);
    try {
      await ref
          .read(ownerStallControllerProvider)
          .setStallOpen(accountId: widget.session.account.id, isOpen: nextOpen);
      if (!mounted) return;
      showKcSnackBar(
        context,
        nextOpen
            ? 'Kantin dibuka untuk menerima pesanan.'
            : 'Kantin ditutup untuk pesanan baru.',
      );
    } catch (error) {
      if (!mounted) return;
      showKcSnackBar(
        context,
        presentAppError(
          error,
          fallback: 'Gagal mengubah status Buka/Tutup kantin.',
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountId = widget.session.account.id;
    final dashboardAsync = ref.watch(ownerDashboardProvider(accountId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            tooltip: 'Akun',
            onPressed: widget.onOpenAccount,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const OwnerLoadingView(message: 'Memuat beranda…'),
          error: (error, _) => OwnerErrorView(
            error: error,
            onRetry: () => ref.invalidate(ownerDashboardProvider(accountId)),
          ),
          data: (dashboard) {
            final stall = dashboard.stallBundle.stall;
            return RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(ownerDashboardProvider(accountId).future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(KcSpacing.md),
                children: [
                  if (stall == null) ...[
                    OwnerEmptyView(
                      icon: Icons.storefront_outlined,
                      title: 'Siapkan kantinmu',
                      description:
                          'Lengkapi profil kantin, siapkan kategori dan minimal satu menu tersedia untuk mulai berjualan.',
                      action: FilledButton(
                        onPressed: widget.onOpenStallTab,
                        child: const Text('Mulai Buat Kantin'),
                      ),
                    ),
                  ] else if (!stall.isListed) ...[
                    OwnerDraftStallCard(
                      stall: stall,
                      onContinueSetup: widget.onOpenStallTab,
                    ),
                  ] else ...[
                    OwnerPublishedStallCard(
                      stall: stall,
                      togglingOpen: _togglingOpen,
                      onToggleOpen: () => _toggleOpen(stall),
                    ),
                    const SizedBox(height: KcSpacing.md),
                    OwnerActiveCountsCard(
                      counts: dashboard.activeCounts,
                      onSelectStatus: widget.onOpenOrdersTab,
                    ),
                    const SizedBox(height: KcSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Perlu Ditangani',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: KcSpacing.xs),
                        TextButton(
                          onPressed: () => widget.onOpenOrdersTab(null),
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: KcSpacing.xs),
                    if (dashboard.attentionOrders.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(KcSpacing.md),
                          child: Text(
                            'Belum ada pesanan aktif saat ini.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < dashboard.attentionOrders.length;
                              i++
                            ) ...[
                              if (i > 0) const Divider(height: 1),
                              OwnerAttentionOrderTile(
                                order: dashboard.attentionOrders[i],
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => OwnerOrderDetailPage(
                                        accountId: accountId,
                                        orderId:
                                            dashboard.attentionOrders[i].id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

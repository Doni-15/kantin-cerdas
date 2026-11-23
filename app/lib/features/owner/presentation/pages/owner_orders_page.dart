import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_order_detail_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_order_lookup_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_order_row_tile.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_state_views.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrdersPage extends ConsumerStatefulWidget {
  const OwnerOrdersPage({
    super.key,
    required this.accountId,
    this.initialStatusFilter,
  });

  final String accountId;
  final OwnerOrderStatus? initialStatusFilter;

  @override
  ConsumerState<OwnerOrdersPage> createState() => _OwnerOrdersPageState();
}

class _OwnerOrdersPageState extends ConsumerState<OwnerOrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!_tabs.indexIsChanging && mounted) setState(() {});
    });
  OwnerOrderStatus? _activeStatusFilter;

  @override
  void initState() {
    super.initState();
    _activeStatusFilter = widget.initialStatusFilter;
  }

  @override
  void didUpdateWidget(covariant OwnerOrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != oldWidget.initialStatusFilter) {
      _activeStatusFilter = widget.initialStatusFilter;
      if (_activeStatusFilter != null && _tabs.index != 0) {
        _tabs.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openLookup() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OwnerOrderLookupPage(accountId: widget.accountId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOnly = _tabs.index == 0;
    final query = (
      accountId: widget.accountId,
      activeOnly: activeOnly,
      status: activeOnly ? _activeStatusFilter : null,
      query: '',
    );
    final ordersAsync = ref.watch(ownerOrdersProvider(query));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan'),
        actions: [
          IconButton(
            tooltip: 'Cari atau pindai pesanan',
            onPressed: _openLookup,
            icon: const Icon(Icons.qr_code_scanner_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (activeOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KcSpacing.md,
                  KcSpacing.sm,
                  KcSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<OwnerOrderStatus?>(
                        initialValue: _activeStatusFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Filter status aktif',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem<OwnerOrderStatus?>(
                            value: null,
                            child: Text('Semua pesanan aktif'),
                          ),
                          DropdownMenuItem<OwnerOrderStatus?>(
                            value: OwnerOrderStatus.menungguKonfirmasi,
                            child: Text('Menunggu Konfirmasi'),
                          ),
                          DropdownMenuItem<OwnerOrderStatus?>(
                            value: OwnerOrderStatus.diproses,
                            child: Text('Diproses'),
                          ),
                          DropdownMenuItem<OwnerOrderStatus?>(
                            value: OwnerOrderStatus.siapDiambil,
                            child: Text('Siap Diambil'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _activeStatusFilter = value),
                      ),
                    ),
                    const SizedBox(width: KcSpacing.xs),
                    IconButton(
                      tooltip: 'Cari nomor pesanan',
                      onPressed: _openLookup,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ordersAsync.when(
                loading: () =>
                    const OwnerLoadingView(message: 'Memuat daftar pesanan…'),
                error: (error, _) => OwnerErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(ownerOrdersProvider(query)),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return OwnerEmptyView(
                      icon: activeOnly
                          ? Icons.receipt_long_outlined
                          : Icons.history_outlined,
                      title: activeOnly
                          ? 'Belum ada pesanan aktif'
                          : 'Belum ada riwayat pesanan',
                      description: activeOnly
                          ? 'Pesanan baru dari pelanggan akan muncul di sini.'
                          : 'Pesanan yang telah selesai atau berakhir akan tercatat di sini.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(ownerOrdersProvider(query).future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(KcSpacing.md),
                      children: [
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0; i < orders.length; i++) ...[
                                if (i > 0) const Divider(height: 1),
                                OwnerOrderRowTile(
                                  order: orders[i],
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => OwnerOrderDetailPage(
                                        accountId: widget.accountId,
                                        orderId: orders[i].id,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: KcSpacing.xs),
                        Text(
                          'Ketuk pesanan untuk melihat rincian dan tindakan.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

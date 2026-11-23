import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/customer/application/customer_cart_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_menu_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_cart_action_button.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_formatters.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_stall_header.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_stall_menu_card.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_stall_schedule_sheet.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';
import 'package:kantin_cerdas/widgets/kc_search_field.dart';

class CustomerStallDetailPage extends ConsumerStatefulWidget {
  const CustomerStallDetailPage({
    super.key,
    required this.accountId,
    required this.stallId,
    this.initialStallName,
    this.onOrderCompleted,
  });

  final String accountId;
  final String stallId;
  final String? initialStallName;
  final ValueChanged<String>? onOrderCompleted;

  @override
  ConsumerState<CustomerStallDetailPage> createState() =>
      _CustomerStallDetailPageState();
}

class _CustomerStallDetailPageState
    extends ConsumerState<CustomerStallDetailPage> {
  final _searchCtrl = TextEditingController();
  var _query = '';
  String? _selectedCategoryId;
  String? _addingMenuId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addQuick(
    CustomerStallSummary stall,
    CustomerMenuSummary menu,
  ) async {
    if (_addingMenuId != null || !stall.canAcceptOrders || !menu.isAvailable) {
      return;
    }
    setState(() => _addingMenuId = menu.id);
    try {
      await ref
          .read(customerCartControllerProvider)
          .addItem(accountId: widget.accountId, menuId: menu.id, quantity: 1);
      if (!mounted) return;
      showCustomerSnackBar(context, '${menu.name} ditambahkan ke keranjang.');
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'CART_DIFFERENT_STALL') {
        setState(() => _addingMenuId = null);
        final replace = await showCustomerConfirmDialog(
          context,
          title: 'Ganti isi keranjang?',
          message:
              'Keranjang saat ini berisi menu dari kantin lain. Ganti seluruh isi keranjang dengan menu dari ${stall.name}?',
          confirmLabel: 'Ganti Keranjang',
        );
        if (!mounted || !replace) return;
        setState(() => _addingMenuId = menu.id);
        try {
          await ref
              .read(customerCartControllerProvider)
              .addItem(
                accountId: widget.accountId,
                menuId: menu.id,
                quantity: 1,
                replaceStall: true,
              );
          if (!mounted) return;
          showCustomerSnackBar(
            context,
            'Keranjang diganti & ${menu.name} ditambahkan.',
          );
        } catch (err) {
          if (!mounted) return;
          showCustomerSnackBar(
            context,
            presentAppError(err, fallback: 'Gagal memperbarui keranjang.'),
          );
        }
      } else {
        showCustomerSnackBar(
          context,
          presentAppError(error, fallback: 'Gagal menambahkan ke keranjang.'),
        );
      }
    } finally {
      if (mounted) setState(() => _addingMenuId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (accountId: widget.accountId, stallId: widget.stallId);
    final detailAsync = ref.watch(customerStallDetailProvider(key));
    final stallName =
        detailAsync.asData?.value.stall.name ??
        widget.initialStallName ??
        'Detail Kantin';

    return Scaffold(
      appBar: AppBar(
        title: Text(stallName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          CustomerCartAppBarButton(
            accountId: widget.accountId,
            onOpenedCartOrder: widget.onOrderCompleted,
          ),
        ],
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => CustomerErrorView(
            error: error,
            fallback: 'Detail kantin tidak dapat dimuat.',
            onRetry: () => ref.invalidate(customerStallDetailProvider(key)),
          ),
          data: (bundle) => _buildContent(context, bundle, key),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CustomerStallDetailBundle bundle,
    CustomerStallKey key,
  ) {
    final theme = Theme.of(context);
    final stall = bundle.stall;
    final photoAsync = stall.hasPhoto
        ? ref.watch(customerStallPhotoProvider(key))
        : null;
    final photoBytes = photoAsync?.asData?.value;
    final qLower = _query.trim().toLowerCase();
    final filteredMenus = bundle.menus
        .where((menu) {
          if (_selectedCategoryId != null &&
              menu.categoryId != _selectedCategoryId) {
            return false;
          }
          if (qLower.isNotEmpty && !menu.name.toLowerCase().contains(qLower)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customerStallDetailProvider(key));
        await ref.read(customerStallDetailProvider(key).future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(KcSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerStallHeader(
                    stall: stall,
                    photoBytes: photoBytes,
                    onShowSchedule: () => showCustomerStallScheduleSheet(
                      context,
                      bundle.schedules,
                    ),
                  ),
                  if (!stall.ownerActive)
                    const CustomerStallNoticeBanner(
                      icon: Icons.block_outlined,
                      message: 'Kantin sementara tidak menerima pesanan.',
                      isError: true,
                    )
                  else if (!stall.isOpen)
                    const CustomerStallNoticeBanner(
                      icon: Icons.info_outline,
                      message:
                          'Kantin sedang tutup. Anda tetap dapat melihat menu, tetapi pesanan baru belum diterima.',
                    ),
                  const SizedBox(height: KcSpacing.md),
                  Text('Daftar Menu', style: theme.textTheme.titleLarge),
                  const SizedBox(height: KcSpacing.xs),
                  KcSearchField(
                    controller: _searchCtrl,
                    hintText: 'Cari menu di kantin ini',
                    onChanged: (value) => setState(() => _query = value),
                    showClearButton: _query.isNotEmpty,
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
                  const SizedBox(height: KcSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: KcSpacing.xs),
                          child: ChoiceChip(
                            label: const Text('Semua'),
                            selected: _selectedCategoryId == null,
                            onSelected: (_) =>
                                setState(() => _selectedCategoryId = null),
                          ),
                        ),
                        for (final cat in bundle.categories)
                          Padding(
                            padding: const EdgeInsets.only(right: KcSpacing.xs),
                            child: ChoiceChip(
                              label: Text(cat.name),
                              selected: _selectedCategoryId == cat.id,
                              onSelected: (_) =>
                                  setState(() => _selectedCategoryId = cat.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filteredMenus.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.all(KcSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: CustomerEmptyView(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Menu tidak ditemukan',
                  subtitle:
                      'Belum ada menu pada kategori atau pencarian yang dipilih.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                KcSpacing.md,
                0,
                KcSpacing.md,
                KcSpacing.lg,
              ),
              sliver: SliverList.separated(
                itemCount: filteredMenus.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: KcSpacing.xs),
                itemBuilder: (context, index) {
                  final menu = filteredMenus[index];
                  return CustomerStallMenuCard(
                    accountId: widget.accountId,
                    menu: menu,
                    canAdd: stall.canAcceptOrders && menu.isAvailable,
                    adding: _addingMenuId == menu.id,
                    onTapCard: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CustomerMenuDetailPage(
                            accountId: widget.accountId,
                            menuId: menu.id,
                            initialMenuName: menu.name,
                            onOrderCompleted: widget.onOrderCompleted,
                          ),
                        ),
                      );
                    },
                    onTapAdd: () => _addQuick(stall, menu),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

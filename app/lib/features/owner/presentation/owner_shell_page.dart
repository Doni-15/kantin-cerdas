import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/features/owner/application/owner_order_controller.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_account_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_home_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_menus_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_orders_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_stall_page.dart';

class OwnerShellPage extends ConsumerStatefulWidget {
  const OwnerShellPage({
    super.key,
    required this.session,
    this.syncInterval = const Duration(seconds: 8),
  });

  final AuthSession session;
  final Duration? syncInterval;

  @override
  ConsumerState<OwnerShellPage> createState() => _OwnerShellPageState();
}

class _OwnerShellPageState extends ConsumerState<OwnerShellPage> {
  var _tabIndex = 0;
  final Set<int> _visitedTabs = {0};
  OwnerOrderStatus? _ordersFilter;
  Timer? _syncTimer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _startSyncTimer();
    _lifecycle = AppLifecycleListener(onResume: _handleAppResume);
  }

  void _startSyncTimer() {
    final interval = widget.syncInterval;
    if (interval == null) return;
    _syncTimer = Timer.periodic(interval, (_) {
      if (mounted && (_tabIndex == 0 || _tabIndex == 1)) {
        _syncActiveTab(fallbackOnly: true);
      }
    });
  }

  void _handleAppResume() {
    if (!mounted) return;
    unawaited(
      ref
          .read(realtimeOrderSyncProvider(widget.session.account.id).notifier)
          .reconnectNow(),
    );
    _syncActiveTab(fallbackOnly: false);
  }

  void _syncActiveTab({bool fallbackOnly = false}) {
    if (!mounted) return;
    if (fallbackOnly &&
        ref.read(realtimeOrderSyncProvider(widget.session.account.id)).isLive) {
      return;
    }
    ref
        .read(ownerOrderControllerProvider)
        .refreshOrders(
          widget.session.account.id,
          includeDashboard: _tabIndex == 0,
          includeOrdersList: _tabIndex == 1,
        );
  }

  void _selectTab(int index, {OwnerOrderStatus? ordersFilter}) {
    setState(() {
      _visitedTabs.add(index);
      if (index == 1) {
        if (ordersFilter != null) _ordersFilter = ordersFilter;
      } else {
        _ordersFilter = null;
      }
      _tabIndex = index;
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OwnerAccountPage(account: widget.session.account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountId = widget.session.account.id;
    ref.watch(realtimeOrderSyncProvider(accountId));
    return PopScope(
      canPop: _tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _tabIndex != 0) {
          setState(() => _tabIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tabIndex,
          children: [
            OwnerHomePage(
              session: widget.session,
              onOpenAccount: _openAccount,
              onOpenStallTab: () => _selectTab(3),
              onOpenOrdersTab: (status) => _selectTab(1, ordersFilter: status),
            ),
            if (_visitedTabs.contains(1))
              OwnerOrdersPage(
                accountId: accountId,
                initialStatusFilter: _ordersFilter,
              )
            else
              const SizedBox.shrink(),
            if (_visitedTabs.contains(2))
              OwnerMenusPage(
                accountId: accountId,
                onOpenStallTab: () => _selectTab(3),
              )
            else
              const SizedBox.shrink(),
            if (_visitedTabs.contains(3))
              OwnerStallPage(
                accountId: accountId,
                onOpenMenusTab: () => _selectTab(2),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => _selectTab(index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Pesanan',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Menu',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Kantin',
            ),
          ],
        ),
      ),
    );
  }
}

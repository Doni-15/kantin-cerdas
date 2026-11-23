import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/ai/presentation/ai_presentation.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';
import 'package:kantin_cerdas/features/customer/application/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_global_search_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_home_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_orders_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_profile_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_bottom_nav_bar.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';

class CustomerShellPage extends ConsumerStatefulWidget {
  const CustomerShellPage({
    super.key,
    required this.session,
    required this.initialPage,
    this.syncInterval = const Duration(seconds: 10),
  });

  final AuthSession session;
  final FutureOr<CatalogPage> initialPage;
  final Duration? syncInterval;

  @override
  ConsumerState<CustomerShellPage> createState() => _CustomerShellPageState();
}

class _CustomerShellPageState extends ConsumerState<CustomerShellPage> {
  var _tabIndex = 0;
  final Set<int> _visitedTabs = {0};
  Timer? _syncTimer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final interval = widget.syncInterval;
    if (interval != null) {
      _syncTimer = Timer.periodic(
        interval,
        (_) => _syncActiveOrdersTab(fallbackOnly: true),
      );
    }
    _lifecycle = AppLifecycleListener(onResume: _handleAppResume);
  }

  void _handleAppResume() {
    if (!mounted) return;
    unawaited(
      ref
          .read(realtimeOrderSyncProvider(widget.session.account.id).notifier)
          .reconnectNow(),
    );
    _syncActiveOrdersTab(fallbackOnly: false);
  }

  void _syncActiveOrdersTab({bool fallbackOnly = false}) {
    if (!mounted || _tabIndex != 2 || !_visitedTabs.contains(2)) return;
    if (fallbackOnly &&
        ref.read(realtimeOrderSyncProvider(widget.session.account.id)).isLive) {
      return;
    }
    ref
        .read(customerOrderControllerProvider)
        .refreshOrders(widget.session.account.id);
  }

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _visitedTabs.add(index);
      _tabIndex = index;
    });
  }

  void _openAiAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiFoodAssistantPage(
          accountId: widget.session.account.id,
          onOpenSearch: () => _selectTab(1),
          onOrderCompleted: (_) => _selectTab(2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountId = widget.session.account.id;
    // Keep account-scoped realtime order sync active while shell is mounted.
    ref.watch(realtimeOrderSyncProvider(accountId));
    // Warm up persisted cart count lazily for Beranda badge without forcing orders/profile fetches.
    ref.watch(customerCartProvider(accountId));

    return PopScope(
      canPop: _tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _tabIndex != 0) {
          setState(() => _tabIndex = 0);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _tabIndex,
          children: [
            CustomerHomePage(
              session: widget.session,
              initialPage: widget.initialPage,
              onOpenSearchTab: () => _selectTab(1),
              onOrderCompleted: (_) => _selectTab(2),
            ),
            if (_visitedTabs.contains(1))
              CustomerGlobalSearchPage(
                session: widget.session,
                onOrderCompleted: (_) => _selectTab(2),
              )
            else
              const SizedBox.shrink(),
            if (_visitedTabs.contains(2))
              CustomerOrdersPage(
                accountId: accountId,
                onExploreCatalog: () => _selectTab(0),
              )
            else
              const SizedBox.shrink(),
            if (_visitedTabs.contains(3))
              CustomerProfilePage(account: widget.session.account)
            else
              const SizedBox.shrink(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: _openAiAssistant,
          tooltip: 'Food Assistant',
          shape: const CircleBorder(),
          child: const Icon(Icons.smart_toy_rounded),
        ),
        bottomNavigationBar: CustomerBottomNavBar(
          selectedIndex: _tabIndex,
          onSelectTab: _selectTab,
        ),
      ),
    );
  }
}

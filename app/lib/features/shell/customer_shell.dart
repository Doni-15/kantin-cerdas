import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_cancellation_banner.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/customer_checkout_banner.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_bottom_navigation.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.navigationShell});

  /// Urutan branch pada router harus sama dengan urutan [CustomerTab].
  final StatefulNavigationShell navigationShell;

  CustomerTab get _currentTab =>
      CustomerTab.values[navigationShell.currentIndex];

<<<<<<< HEAD
  void _selectTab(CustomerTab tab) {
    navigationShell.goBranch(
      tab.index,
      initialLocation: tab.index == navigationShell.currentIndex,
    );
=======
class _CustomerShellState
    extends State<CustomerShell> {
  CustomerTab _currentTab =
      CustomerTab.home;

  // =============================================================
  // PINDAH TAB
  // =============================================================

  void _changeTab(CustomerTab tab) {
    setState(() {
      _currentTab = tab;
    });
  }

  // =============================================================
  // KEMBALI KE HOME
  // =============================================================

  void _backToHome() {
    setState(() {
      _currentTab = CustomerTab.home;
    });
  }

  // =============================================================
  // HALAMAN YANG DITAMPILKAN
  // =============================================================

  Widget get _currentPage {
    return switch (_currentTab) {
      // HOME
      CustomerTab.home =>
        const CustomerHomePage(),

      // PESANAN
      CustomerTab.orders =>
        const CustomerOrdersPage(),

      // CHAT AI
      CustomerTab.ai =>
        CustomerAiChatPage(
          onBackToHome: _backToHome,
        ),

      // RIWAYAT
      CustomerTab.history =>
        const CustomerHistoryPage(),

      // PROFIL
      CustomerTab.profile =>
        CustomerProfilePage(
          user: widget.user,
        ),
    };
>>>>>>> origin/rio/kantin-cerdas
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _currentTab;
    final isAiChat = currentTab == CustomerTab.ai;

<<<<<<< HEAD
    return PopScope<Object?>(
      canPop: !isAiChat,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isAiChat) {
          context.go(Routes.customerHome);
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const CustomerCheckoutBanner(),
              const CustomerCancellationBanner(),
              Expanded(child: navigationShell),
            ],
          ),
=======
      body: _currentPage,

      // ===========================================================
      // TOMBOL AI DI TENGAH
      // ===========================================================

      floatingActionButton:
          FloatingActionButton(
        shape: const CircleBorder(),
        elevation: 6,

        onPressed: () {
          _changeTab(
            CustomerTab.ai,
          );
        },

        child: const Icon(
          Icons.smart_toy_outlined,
>>>>>>> origin/rio/kantin-cerdas
        ),
        floatingActionButton: isAiChat
            ? null
            : FloatingActionButton(
                tooltip: 'Asisten AI',
                shape: const CircleBorder(),
                onPressed: () {
                  _selectTab(CustomerTab.ai);
                },
                child: const Icon(Icons.smart_toy_outlined),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: isAiChat
            ? null
            : CustomerBottomNavigation(
                currentTab: currentTab,
                onTabSelected: (tab) {
                  _selectTab(tab);
                },
              ),
      ),
    );
  }
}

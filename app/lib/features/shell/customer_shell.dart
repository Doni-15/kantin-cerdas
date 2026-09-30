import 'package:flutter/material.dart';

import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';

import 'package:kantin_cerdas/features/customer/presentation/pages/customer_ai_chat_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_history_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_home_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_orders_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_profile_page.dart';

import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_bottom_navigation.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<CustomerShell> createState() =>
      _CustomerShellState();
}

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===========================================================
      // HALAMAN UTAMA
      // ===========================================================

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
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerDocked,

      // ===========================================================
      // BOTTOM NAVIGATION
      // ===========================================================

      bottomNavigationBar:
          CustomerBottomNavigation(
        currentTab: _currentTab,

        onTabSelected: (tab) {
          _changeTab(tab);
        },
      ),
    );
  }
}
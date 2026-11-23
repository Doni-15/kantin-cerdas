import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_account_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_applications_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_stalls_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_users_page.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';

class AdminShellPage extends ConsumerStatefulWidget {
  const AdminShellPage({super.key, required this.session});

  final AuthSession session;

  @override
  ConsumerState<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends ConsumerState<AdminShellPage> {
  var _tabIndex = 0;
  final Set<int> _visitedTabs = {0};

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _visitedTabs.add(index);
      _tabIndex = index;
    });
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminAccountPage(account: widget.session.account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountId = widget.session.account.id;
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
            AdminDashboardPage(
              session: widget.session,
              onOpenAccount: _openAccount,
              onOpenApplicationsTab: () => _selectTab(1),
              onOpenUsersTab: () => _selectTab(2),
              onOpenStallsTab: () => _selectTab(3),
            ),
            if (_visitedTabs.contains(1))
              AdminApplicationsPage(accountId: accountId)
            else
              const SizedBox.shrink(),
            if (_visitedTabs.contains(2))
              AdminUsersPage(accountId: accountId)
            else
              const SizedBox.shrink(),
            if (_visitedTabs.contains(3))
              AdminStallsPage(accountId: accountId)
            else
              const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Pengajuan',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Pengguna',
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

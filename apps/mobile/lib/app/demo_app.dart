import 'package:flutter/material.dart';

enum DemoRole { student, manager }

/// Sesi contoh lokal; bukan autentikasi backend.
class DemoSession {
  const DemoSession.student()
      : role = DemoRole.student,
        name = 'Doni',
        email = 'doni@example.com',
        stallId = null;

  const DemoSession.manager()
      : role = DemoRole.manager,
        name = 'Bu Rina',
        email = 'rina@example.com',
        stallId = 'dapur-bu-rina';

  final DemoRole role;
  final String name;
  final String email;
  final String? stallId;
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key, required this.session});

  final DemoSession session;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFAFAF8);
    return MaterialApp(
      title: 'KantinCerdas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PlusJakartaSans',
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE85D2A),
          primary: const Color(0xFFC74418),
          surface: background,
          onSurface: const Color(0xFF251B17),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          toolbarHeight: 56,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF9B341B),
          unselectedItemColor: Color(0xFF6D5A50),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: RoleShell(key: ValueKey(session.role), session: session),
    );
  }
}

class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.session});

  final DemoSession session;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final manager = session.role == DemoRole.manager;
    final labels = manager
        ? ['Dashboard', 'Pesanan', 'Menu', 'Profil']
        : ['Beranda', 'Pesanan', 'Profil'];
    final icons = manager
        ? [
            Icons.grid_view_outlined,
            Icons.receipt_long_outlined,
            Icons.restaurant_menu,
            Icons.person_outline,
          ]
        : [
            Icons.home_outlined,
            Icons.receipt_long_outlined,
            Icons.person_outline,
          ];

    final profile = selectedIndex == labels.length - 1;
    String title = labels[selectedIndex];
    String description = 'Daftar pesanan akan ditampilkan di sini.';

    if (selectedIndex == 0) {
      title = manager
          ? 'Selamat siang, ${session.name}'
          : 'Halo, ${session.name}';
      description = manager
          ? 'Ringkasan stan akan ditampilkan di sini.'
          : 'Mau makan apa hari ini?';
    } else if (profile) {
      title = session.name;
      description = session.email;
    } else if (manager && selectedIndex == 2) {
      description = 'Daftar menu stan akan ditampilkan di sini.';
    }

    return Scaffold(
      appBar: AppBar(title: Text(labels[selectedIndex])),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(manager ? 'Dapur Bu Rina' : 'Kantin Kampus'),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(description),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => setState(() => selectedIndex = index),
            items: [
              for (var i = 0; i < labels.length; i++)
                BottomNavigationBarItem(
                  icon: Icon(icons[i]),
                  label: labels[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

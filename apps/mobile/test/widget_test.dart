import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/main.dart' as default_entry;
import 'package:kantin_cerdas/main_manager.dart' as manager;
import 'package:kantin_cerdas/main_student.dart' as student;

void main() {
  testWidgets('Mahasiswa membuka sesi Doni dan tiga tab', (tester) async {
    student.main();
    await tester.pumpAndSettle();

    expect(find.text('Halo, Doni'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.items.length, 3);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('doni@example.com'), findsOneWidget);
    expect(find.text('rina@example.com'), findsNothing);
  });

  testWidgets('Pengelola membuka sesi Bu Rina dan empat tab', (tester) async {
    manager.main();
    await tester.pumpAndSettle();

    expect(find.text('Selamat siang, Bu Rina'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.items.length, 4);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(
      find.text('Daftar menu stan akan ditampilkan di sini.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('rina@example.com'), findsOneWidget);
    expect(find.text('doni@example.com'), findsNothing);
  });

  testWidgets('Default entry membuka mahasiswa', (tester) async {
    default_entry.main();
    await tester.pumpAndSettle();
    expect(find.text('Halo, Doni'), findsOneWidget);
  });

  testWidgets('Pergantian peran mereset tab', (tester) async {
    manager.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    student.main();
    await tester.pumpAndSettle();
    expect(find.text('Halo, Doni'), findsOneWidget);
    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.currentIndex, 0);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/app/demo_app.dart';
import 'package:kantin_cerdas/core/data/session_repository.dart';
import 'package:kantin_cerdas/core/models/demo_session.dart';

class StubSessionRepository implements SessionRepository {
  @override
  DemoSession current() => const DemoSession.manager();
}

void main() {
  testWidgets('DemoApp memakai sesi dari repository yang diinjeksi', (
    tester,
  ) async {
    await tester.pumpWidget(
      DemoApp(sessionRepository: StubSessionRepository()),
    );

    expect(find.text('Selamat siang, Bu Rina'), findsOneWidget);
    expect(find.text('Halo, Doni'), findsNothing);
    expect(find.text('Beranda'), findsNothing);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('rina@example.com'), findsOneWidget);
    expect(find.text('doni@example.com'), findsNothing);
  });
}

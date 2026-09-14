import '../core/data/fake_session_repository.dart';
import '../core/data/session_repository.dart';
import '../core/models/demo_session.dart';
import 'demo_app.dart';

/// Composition root: memilih dan menghubungkan dependensi aplikasi.
DemoApp createDemoApp(DemoRole role) {
  final session = switch (role) {
    DemoRole.student => const DemoSession.student(),
    DemoRole.manager => const DemoSession.manager(),
  };

  final SessionRepository repository = FakeSessionRepository(session);

  return DemoApp(sessionRepository: repository);
}

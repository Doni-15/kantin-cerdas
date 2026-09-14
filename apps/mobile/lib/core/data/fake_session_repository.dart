import '../models/demo_session.dart';
import 'session_repository.dart';

/// Implementasi lokal untuk demo tanpa login atau backend.
class FakeSessionRepository implements SessionRepository {
  const FakeSessionRepository(this._session);

  final DemoSession _session;

  @override
  DemoSession current() => _session;
}

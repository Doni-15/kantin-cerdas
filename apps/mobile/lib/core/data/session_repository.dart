import '../models/demo_session.dart';

/// Kontrak pembacaan sesi. UI tidak bergantung pada sumber datanya.
abstract interface class SessionRepository {
  DemoSession current();
}

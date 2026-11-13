import '../support/simulation_harness.dart';

void main() {
  group(
    'Login simulasi yang tertunda tidak boleh menimpa logout, reset, atau akun yang lebih baru',
    () {
      testWidgets('logout cancels an earlier delayed simulation login', (
        tester,
      ) async {
        final store = SimulationStore.memory()
          ..latency = const Duration(seconds: 1);
        final auth = SimulationAuthRepository(store);
        final pending = auth.login(
          identifier: 'pelanggan',
          password: 'Simulasi123!',
        );
        final rejected = expectLater(
          pending,
          throwsA(isA<AuthOperationSupersededFailure>()),
        );
        await auth.logout();
        await tester.pump(const Duration(seconds: 1));
        await rejected;
        expect(store.sessionUser, isNull);
      });

      testWidgets('reset cannot be undone by a pending simulation login', (
        tester,
      ) async {
        final store = SimulationStore.memory()
          ..latency = const Duration(seconds: 1);
        final auth = SimulationAuthRepository(store);
        final pending = auth.login(
          identifier: 'pelanggan',
          password: 'Simulasi123!',
        );
        final rejected = expectLater(
          pending,
          throwsA(isA<AuthOperationSupersededFailure>()),
        );
        await store.reset();
        await tester.pump(const Duration(seconds: 1));
        await rejected;
        expect(store.sessionUser, isNull);
      });

      testWidgets('a delayed login cannot replace a newer account', (
        tester,
      ) async {
        final store = SimulationStore.memory()
          ..latency = const Duration(seconds: 1);
        final auth = SimulationAuthRepository(store);
        final old = auth.login(
          identifier: 'pelanggan',
          password: 'Simulasi123!',
        );
        final rejected = expectLater(
          old,
          throwsA(isA<AuthOperationSupersededFailure>()),
        );
        store.latency = Duration.zero;
        final owner = await auth.login(
          identifier: 'pemilik',
          password: 'Simulasi123!',
        );
        await tester.pump(const Duration(seconds: 1));
        await rejected;
        expect(store.sessionUser!.id, owner.id);
      });
    },
  );
}

import '../../../../support/paged_session_container.dart';
import '../../../../support/simulation_harness.dart';

void main() {
  group('Feed admin menolak halaman yang melebihi limit', () {
    test(
      'admin user feed rejects a page larger than the requested limit',
      () async {
        final c = await makeContainer(SimulationStore.memory(), 'admin');
        final p = adminUsersProvider((search: '', cursor: null));
        c.listen(p, (_, _) {});
        await expectLater(
          c.read(p.future),
          throwsA(isA<AdminInvalidDataFailure>()),
        );
      },
    );

    test(
      'admin application feed rejects a page larger than the requested limit',
      () async {
        final c = await makeContainer(SimulationStore.memory(), 'admin');
        final p = adminApplicationsProvider((status: null, cursor: null));
        c.listen(p, (_, _) {});
        await expectLater(
          c.read(p.future),
          throwsA(isA<AdminInvalidDataFailure>()),
        );
      },
    );
  });
}

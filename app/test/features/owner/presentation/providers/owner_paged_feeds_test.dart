import '../../../../support/paged_session_container.dart';
import '../../../../support/simulation_harness.dart';

void main() {
  group('Feed owner menolak halaman yang melebihi limit', () {
    test(
      'owner menu feed rejects a page larger than the requested limit',
      () async {
        final c = await makeContainer(SimulationStore.memory(), 'pemilik');
        final p = ownerMenusProvider((
          search: '',
          available: null,
          cursor: null,
        ));
        c.listen(p, (_, _) {});
        await expectLater(
          c.read(p.future),
          throwsA(isA<OwnerInvalidDataFailure>()),
        );
      },
    );
  });
}

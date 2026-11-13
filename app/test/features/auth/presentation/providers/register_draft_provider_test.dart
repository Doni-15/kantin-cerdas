import '../../../../support/simulation_harness.dart';

void main() {
  group('RegisterDraft', () {
    test(
      'menyimpan draf registrasi dan membersihkan password dengan aman',
      () async {
        final h = await createHarness();
        addTearDown(h.dispose);
        final sub = h.container.listen(registerDraftProvider, (_, _) {});
        addTearDown(sub.close);

        h.container
            .read(registerDraftProvider.notifier)
            .setDraft(
              const RegisterDraft(
                name: 'Budi',
                email: 'budi@kampus.ac.id',
                password: 'Password123!',
              ),
            );
        expect(
          h.container.read(registerDraftProvider)?.password,
          'Password123!',
        );

        h.container.read(registerDraftProvider.notifier).clearPassword();
        expect(h.container.read(registerDraftProvider)?.password, isEmpty);
        expect(
          h.container.read(registerDraftProvider)?.email,
          'budi@kampus.ac.id',
        );
      },
    );
  });
}

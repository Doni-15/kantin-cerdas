import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/owner/data/storage/secure_owner_mutation_journal.dart';

void main() {
  group('SecureMutationJournalBase (PROD-NEW-04)', () {
    test(
      'menangani ArgumentError dari invarian domain pada entri jurnal rusak dan menghapusnya dengan aman',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        // Menyimpan entri jurnal owner dengan mutationId kosong yang memicu ArgumentError di PendingOwnerMutation
        FlutterSecureStorage.setMockInitialValues(<String, String>{
          'kantin_cerdas.owner.mutation.v1.owner-1':
              '{"ownerId":"owner-1","mutationId":"   ","stallId":"stall-1","kind":"saveStall","targetId":"stall-1","expectedVersion":1}',
        });
        final journal = SecureOwnerMutationJournal(
          const FlutterSecureStorage(),
        );

        final pending = await journal.read('owner-1');
        expect(pending, isNull);
      },
    );
  });
}

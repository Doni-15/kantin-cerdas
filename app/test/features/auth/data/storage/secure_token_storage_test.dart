import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/data/storage/secure_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureTokenStorage (LOW-03)', () {
    test(
      'menyimpan, membaca kembali, dan menghapus AuthTokens di FlutterSecureStorage',
      () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{});
        final storage = SecureTokenStorage(
          storage: const FlutterSecureStorage(),
        );
        final expiresAt = DateTime.utc(2027, 1, 15, 8, 30);

        await storage.save(
          AuthTokens(
            accessToken: 'tok-abc',
            refreshToken: 'ref-xyz',
            expiresAt: expiresAt,
          ),
        );

        final loaded = await storage.read();
        expect(loaded?.accessToken, 'tok-abc');
        expect(loaded?.refreshToken, 'ref-xyz');
        expect(loaded?.expiresAt, expiresAt);

        await storage.clear();
        expect(await storage.read(), isNull);
      },
    );

    test(
      'melempar DataParsingException ketika JSON di penyimpanan rusak atau token kosong',
      () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{
          'kantin_cerdas.auth.tokens.v1': '{corrupted-json',
        });
        final storage = SecureTokenStorage(
          storage: const FlutterSecureStorage(),
        );

        await expectLater(storage.read(), throwsA(isA<DataParsingException>()));
        await expectLater(
          storage.save(const AuthTokens(accessToken: '   ')),
          throwsA(isA<DataParsingException>()),
        );
      },
    );
  });
}

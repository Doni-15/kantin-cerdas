import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/supabase_config.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  late SupabaseClientFactory factory;

  setUp(() {
    final config = SupabaseConfig.fromEnv(
      EnvConfig.fromMap({
        'SUPABASE_PROJECT_REF': 'exampleprojectref001',
        'SUPABASE_URL': 'https://exampleprojectref001.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        'SUPABASE_SECRET_KEY': 'sb_secret_test',
      }),
    );

    factory = SupabaseClientFactory(config: config);
  });

  group('SupabaseClientFactory', () {
    test('creates and disposes server client', () async {
      final client = factory.createServerClient();

      expect(client, isA<SupabaseClient>());

      await client.dispose();
    });

    test('creates and disposes auth client', () async {
      final client = factory.createAuthClient();

      expect(client, isA<SupabaseClient>());
      expect(() => client.auth, returnsNormally);

      await client.dispose();
    });

    test('creates and disposes user client', () async {
      final client = factory.createUserClient(
        accessToken: 'test-user-access-token',
      );

      expect(client, isA<SupabaseClient>());

      await client.dispose();
    });

    test('rejects empty user access token', () {
      expect(
        () => factory.createUserClient(accessToken: '  '),
        throwsArgumentError,
      );
    });
  });
}

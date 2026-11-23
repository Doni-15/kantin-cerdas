import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/supabase_config.dart';
import 'package:test/test.dart';

void main() {
  const validValues = {
    'SUPABASE_PROJECT_REF': 'exampleprojectref001',
    'SUPABASE_URL': 'https://exampleprojectref001.supabase.co',
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
    'SUPABASE_SECRET_KEY': 'sb_secret_test',
  };

  group('SupabaseConfig', () {
    test('reads Supabase configuration', () {
      final config = SupabaseConfig.fromEnv(EnvConfig.fromMap(validValues));

      expect(config.projectRef, 'exampleprojectref001');
      expect(config.url.toString(), 'https://exampleprojectref001.supabase.co');
      expect(config.publishableKey, 'sb_publishable_test');
      expect(config.secretKey, 'sb_secret_test');
      expect(config.requestTimeout, const Duration(seconds: 15));
      expect(config.maxRetries, 2);
    });

    test('reads custom timeout and retry values', () {
      final config = SupabaseConfig.fromEnv(
        EnvConfig.fromMap({
          ...validValues,
          'SUPABASE_REQUEST_TIMEOUT_SECONDS': '30',
          'SUPABASE_MAX_RETRIES': '4',
        }),
      );

      expect(config.requestTimeout, const Duration(seconds: 30));
      expect(config.maxRetries, 4);
    });

    test('derives the project reference from the configured URL', () {
      expect(
        SupabaseConfig.fromEnv(
          EnvConfig.fromMap({...validValues}..remove('SUPABASE_PROJECT_REF')),
        ).projectRef,
        'exampleprojectref001',
      );
    });

    test('rejects a project URL with a non-root path or alternate port', () {
      for (final url in [
        'https://exampleprojectref001.supabase.co/auth/v1',
        'https://exampleprojectref001.supabase.co:8443',
      ]) {
        expect(
          () => SupabaseConfig.fromEnv(
            EnvConfig.fromMap({...validValues, 'SUPABASE_URL': url}),
          ),
          throwsFormatException,
        );
      }
    });

    test('rejects invalid project reference', () {
      expect(
        () => SupabaseConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'SUPABASE_PROJECT_REF': 'invalid-ref',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid URL', () {
      expect(
        () => SupabaseConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'SUPABASE_URL': 'http://example.com',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid publishable key prefix', () {
      expect(
        () => SupabaseConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'SUPABASE_PUBLISHABLE_KEY': 'invalid_key',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid secret key prefix', () {
      expect(
        () => SupabaseConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'SUPABASE_SECRET_KEY': 'invalid_secret',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid retry count', () {
      expect(
        () => SupabaseConfig.fromEnv(
          EnvConfig.fromMap({...validValues, 'SUPABASE_MAX_RETRIES': '11'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects negative retry count', () {
      expect(
        () => SupabaseConfig.fromEnv(
          EnvConfig.fromMap({...validValues, 'SUPABASE_MAX_RETRIES': '-1'}),
        ),
        throwsFormatException,
      );
    });
  });
}

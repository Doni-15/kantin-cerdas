import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/supabase_config.dart';
import 'package:test/test.dart';

void main() {
  const validValues = {
    'SUPABASE_PROJECT_REF': 'diprwrdomyqrhllqlche',
    'SUPABASE_URL': 'https://diprwrdomyqrhllqlche.supabase.co',
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
    'SUPABASE_SECRET_KEY': 'sb_secret_test',
  };

  group('SupabaseConfig', () {
    test('reads Supabase configuration', () {
      final config = SupabaseConfig.fromEnv(EnvConfig.fromMap(validValues));

      expect(config.projectRef, 'diprwrdomyqrhllqlche');
      expect(config.url.toString(), 'https://diprwrdomyqrhllqlche.supabase.co');
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

    test('rejects missing project reference', () {
      expect(
        () => SupabaseConfig.fromEnv(
          EnvConfig.fromMap({...validValues}..remove('SUPABASE_PROJECT_REF')),
        ),
        throwsFormatException,
      );
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

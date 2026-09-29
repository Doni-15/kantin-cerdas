import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/settings/app_settings_provider.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_dummy_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/storage/persistent_token_storage.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_dummy_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.create();
  });

  // "Restart aplikasi": instance dummy baru yang memakai storage yang sama.
  AuthDummyDataSource newAuthDummy() =>
      AuthDummyDataSource(latency: Duration.zero, storage: storage);

  CanteenApplicationDummyDataSource newCanteenDummy(String? userId) =>
      CanteenApplicationDummyDataSource(
        currentUserId: () => userId,
        latency: Duration.zero,
        storage: storage,
      );

  group('LocalStorage', () {
    test('readJson: belum ada -> null', () {
      expect(storage.readJson('k'), isNull);
    });

    test('writeJson lalu readJson', () async {
      expect(await storage.writeJson('k', {'a': 1, 'b': 'x'}), isTrue);
      expect(storage.readJson('k'), {'a': 1, 'b': 'x'});
    });

    test('readJson: isi rusak atau bukan object -> null', () async {
      SharedPreferences.setMockInitialValues({'rusak': '{rusak', 'list': '[1]'});
      final broken = await LocalStorage.create();

      expect(broken.readJson('rusak'), isNull);
      expect(broken.readJson('list'), isNull);
    });
  });

  group('PersistentTokenStorage', () {
    test('save, read, clear', () async {
      final tokens = PersistentTokenStorage(storage);
      final expiresAt = DateTime(2030, 1, 1);

      expect(await tokens.read(), isNull);

      await tokens.save(
        AuthTokens(accessToken: 'a', refreshToken: 'r', expiresAt: expiresAt),
      );

      final saved = await tokens.read();
      expect(saved?.accessToken, 'a');
      expect(saved?.refreshToken, 'r');
      expect(saved?.expiresAt, expiresAt);

      await tokens.clear();
      expect(await tokens.read(), isNull);
    });

    test('data rusak -> null dan dibersihkan', () async {
      await storage.setString(StorageKeys.authTokens, '{"access_token": 1}');
      final tokens = PersistentTokenStorage(storage);

      expect(await tokens.read(), isNull);
      expect(storage.getString(StorageKeys.authTokens), isNull);
    });
  });

  group('settings', () {
    ProviderContainer newContainer() {
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('default lalu tersimpan setelah restart', () async {
      final first = newContainer();

      expect(first.read(appSettingsProvider).themeMode, ThemeMode.system);
      expect(first.read(appSettingsProvider).notificationsEnabled, isTrue);

      final notifier = first.read(appSettingsProvider.notifier);
      expect(await notifier.setThemeMode(ThemeMode.dark), isTrue);
      expect(await notifier.setNotificationsEnabled(false), isTrue);

      final second = newContainer();

      expect(second.read(appSettingsProvider).themeMode, ThemeMode.dark);
      expect(second.read(appSettingsProvider).notificationsEnabled, isFalse);
    });

    test('nilai tersimpan tidak dikenal -> default', () async {
      await storage.setString(StorageKeys.themeMode, 'neon');

      expect(
        newContainer().read(appSettingsProvider).themeMode,
        ThemeMode.system,
      );
    });
  });

  group('dummy auth (persisten)', () {
    test('akun hasil register bertahan setelah restart', () async {
      await newAuthDummy().register(
        name: 'Siti',
        username: 'siti',
        email: 'siti@mail.com',
        password: 'rahasia123',
      );

      final response = await newAuthDummy().login(
        identifier: 'siti',
        password: 'rahasia123',
      );

      expect(response.user.username, 'siti');
    });

    test('id akun baru melanjutkan hitungan setelah restart', () async {
      final first = await newAuthDummy().register(
        name: 'A',
        username: 'akun.a',
        email: 'a@mail.com',
        password: 'rahasia123',
      );
      final second = await newAuthDummy().register(
        name: 'B',
        username: 'akun.b',
        email: 'b@mail.com',
        password: 'rahasia123',
      );

      expect(second.id, isNot(first.id));
    });

    test('session bertahan setelah restart, logout mencabutnya', () async {
      final login = await newAuthDummy().login(
        identifier: 'customer',
        password: '123456',
      );

      final user = await newAuthDummy().getCurrentUser(
        accessToken: login.accessToken,
      );
      expect(user.username, 'customer');

      await newAuthDummy().logout(refreshToken: login.refreshToken);

      await expectLater(
        newAuthDummy().getCurrentUser(accessToken: login.accessToken),
        throwsA(isA<ApiException>()),
      );
    });

    test('data tersimpan rusak -> mulai dari kondisi awal', () async {
      await storage.setString(StorageKeys.authDummyState, '{rusak');

      final response = await newAuthDummy().login(
        identifier: 'admin',
        password: '123456',
      );

      expect(response.user.username, 'admin');
    });
  });

  group('dummy pengajuan kantin (persisten)', () {
    test('pengajuan dan perubahan status bertahan setelah restart', () async {
      final created = await newCanteenDummy('user-a').submit(
        name: 'Kantin Berkah',
        description: 'Kantin sehat',
        address: 'Jl. Mawar 1',
      );

      await newCanteenDummy('user-a').updateStatus(
        id: created.id,
        status: 'approved',
      );

      final restored = await newCanteenDummy('user-a').getMyApplication();

      expect(restored?.name, 'Kantin Berkah');
      expect(restored?.status, 'approved');
    });

    test('tetap terikat per user setelah restart', () async {
      await newCanteenDummy('user-a').submit(
        name: 'Kantin Berkah',
        description: 'Kantin sehat',
        address: 'Jl. Mawar 1',
      );

      expect(await newCanteenDummy('user-b').getMyApplication(), isNull);
    });

    test('hapus pengajuan bertahan setelah restart', () async {
      await newCanteenDummy('user-a').submit(
        name: 'Kantin Berkah',
        description: 'Kantin sehat',
        address: 'Jl. Mawar 1',
      );
      await newCanteenDummy('user-a').deleteMyApplication();

      expect(await newCanteenDummy('user-a').getMyApplication(), isNull);
    });
  });

  group('pemulihan sesi', () {
    ProviderContainer newApp() {
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          authDataSourceProvider.overrideWithValue(newAuthDummy()),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('sesi dipulihkan setelah restart, hilang setelah logout', () async {
      final first = newApp();
      await first.read(loginUseCaseProvider).execute(
            identifier: 'owner',
            password: '123456',
          );

      final second = newApp();
      await second.read(authStateProvider.notifier).restoreSession();
      expect(second.read(authStateProvider)?.username, 'owner');

      await second.read(authStateProvider.notifier).logout();
      expect(second.read(authStateProvider), isNull);
      expect(storage.getString(StorageKeys.authTokens), isNull);

      final third = newApp();
      await third.read(authStateProvider.notifier).restoreSession();
      expect(third.read(authStateProvider), isNull);
    });

    test('tanpa sesi tersimpan -> tetap belum login', () async {
      final app = newApp();
      await app.read(authStateProvider.notifier).restoreSession();

      expect(app.read(authStateProvider), isNull);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _customer = User(
  id: '3',
  username: 'customer',
  email: 'customer@kantincerdas.com',
  name: 'Andi (Customer)',
  role: UserRole.customer,
  isActive: true,
);

const _otherCustomer = User(
  id: '9',
  username: 'lain',
  email: 'lain@kantincerdas.com',
  name: 'Pengguna Lain',
  role: UserRole.customer,
  isActive: true,
);

/// Satu "proses aplikasi": container baru = aplikasi dibuka ulang,
/// storage yang sama = data di perangkat yang sama.
ProviderContainer _openApp(LocalStorage storage, User user) {
  final container = ProviderContainer(
    overrides: [localStorageProvider.overrideWithValue(storage)],
  );

  container.read(authStateProvider.notifier).setUser(user);

  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('pengajuan kantin tetap ada setelah aplikasi dibuka ulang', () async {
    final storage = await LocalStorage.create();

    final firstRun = _openApp(storage, _customer);
    addTearDown(firstRun.dispose);

    await firstRun
        .read(submitCanteenApplicationUseCaseProvider)
        .execute(
          name: 'Kantin Sehat',
          description: 'Makanan sehat setiap hari',
          address: 'Gedung A lantai 1',
        );

    final secondRun = _openApp(storage, _customer);
    addTearDown(secondRun.dispose);

    final restored = await secondRun
        .read(canteenApplicationRepositoryProvider)
        .getMyApplication();

    expect(restored, isNotNull);
    expect(restored!.name, 'Kantin Sehat');
    expect(restored.status, CanteenApplicationStatus.submitted);
  });

  test('pengajuan satu user tidak terlihat oleh user lain', () async {
    final storage = await LocalStorage.create();

    final firstRun = _openApp(storage, _customer);
    addTearDown(firstRun.dispose);

    await firstRun
        .read(submitCanteenApplicationUseCaseProvider)
        .execute(
          name: 'Kantin Sehat',
          description: 'Makanan sehat setiap hari',
          address: 'Gedung A lantai 1',
        );

    final otherRun = _openApp(storage, _otherCustomer);
    addTearDown(otherRun.dispose);

    final other = await otherRun
        .read(canteenApplicationRepositoryProvider)
        .getMyApplication();

    expect(other, isNull);
  });
}

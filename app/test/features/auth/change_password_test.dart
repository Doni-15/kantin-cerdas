import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_dummy_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/data/storage/in_memory_token_storage.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Satu "proses aplikasi": datasource + token storage baru.
/// Storage yang sama = data di perangkat yang sama.
AuthRepositoryImpl _openApp([LocalStorage? storage]) {
  return AuthRepositoryImpl(
    dataSource: AuthDummyDataSource(latency: Duration.zero, storage: storage),
    tokenStorage: InMemoryTokenStorage(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('password berubah: yang lama ditolak, yang baru bisa login', () async {
    final app = _openApp();

    await app.login(identifier: 'customer', password: '123456');
    await app.changePassword(
      currentPassword: '123456',
      newPassword: 'rahasia1',
    );

    await expectLater(
      app.login(identifier: 'customer', password: '123456'),
      throwsA(isA<InvalidCredentialsFailure>()),
    );

    final user = await app.login(identifier: 'customer', password: 'rahasia1');
    expect(user.username, 'customer');
  });

  test('password saat ini salah ditolak dan password tidak berubah', () async {
    final app = _openApp();

    await app.login(identifier: 'owner', password: '123456');

    await expectLater(
      app.changePassword(currentPassword: 'salah123', newPassword: 'rahasia1'),
      throwsA(isA<InvalidCurrentPasswordFailure>()),
    );

    final user = await app.login(identifier: 'owner', password: '123456');
    expect(user.username, 'owner');
  });

  test('tanpa sesi login: SessionExpiredFailure', () async {
    final app = _openApp();

    await expectLater(
      app.changePassword(currentPassword: '123456', newPassword: 'rahasia1'),
      throwsA(isA<SessionExpiredFailure>()),
    );
  });

  test('use case menolak password baru yang pendek atau sama', () async {
    final useCase = ChangePasswordUseCase(_openApp());

    await expectLater(
      useCase.execute(currentPassword: '123456', newPassword: '123'),
      throwsA(isA<ValidationFailure>()),
    );
    await expectLater(
      useCase.execute(currentPassword: '123456', newPassword: '123456'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test(
    'password baru akun seed tetap berlaku setelah aplikasi dibuka ulang',
    () async {
      final storage = await LocalStorage.create();

      final firstRun = _openApp(storage);
      await firstRun.login(identifier: 'admin', password: '123456');
      await firstRun.changePassword(
        currentPassword: '123456',
        newPassword: 'rahasia1',
      );

      final secondRun = _openApp(storage);

      await expectLater(
        secondRun.login(identifier: 'admin', password: '123456'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );

      final user = await secondRun.login(
        identifier: 'admin',
        password: 'rahasia1',
      );
      expect(user.username, 'admin');
    },
  );
}

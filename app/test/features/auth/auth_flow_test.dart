import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_dummy_datasource.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/user_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/data/storage/in_memory_token_storage.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/login_usecase.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/register_usecase.dart';

void main() {
  late InMemoryTokenStorage tokenStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
    repository = AuthRepositoryImpl(
      dataSource: AuthDummyDataSource(latency: Duration.zero),
      tokenStorage: tokenStorage,
    );
  });

  group('login', () {
    test('akun seed berhasil login dan token tersimpan', () async {
      final user = await repository.login(
        identifier: 'admin',
        password: '123456',
      );

      expect(user.role, UserRole.admin);
      expect(await tokenStorage.read(), isNotNull);
    });

    test('bisa login memakai email', () async {
      final user = await repository.login(
        identifier: 'pemilik@kantincerdas.com',
        password: '123456',
      );

      expect(user.role, UserRole.owner);
    });

    test('password salah -> InvalidCredentialsFailure', () async {
      await expectLater(
        repository.login(identifier: 'admin', password: 'salah'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      expect(await tokenStorage.read(), isNull);
    });

    test('user tidak ada -> InvalidCredentialsFailure', () async {
      await expectLater(
        repository.login(identifier: 'tidakada', password: '123456'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('akun nonaktif -> AccountDisabledFailure', () async {
      await expectLater(
        repository.login(identifier: 'inactive', password: '123456'),
        throwsA(isA<AccountDisabledFailure>()),
      );
    });

    test('skenario offline / timeout -> NetworkFailure', () async {
      await expectLater(
        repository.login(identifier: 'offline', password: '123456'),
        throwsA(isA<NetworkFailure>()),
      );
      await expectLater(
        repository.login(identifier: 'timeout', password: '123456'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('skenario error500 -> UnknownFailure', () async {
      await expectLater(
        repository.login(identifier: 'error500', password: '123456'),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('register', () {
    test('akun baru bisa login dengan password yang didaftarkan', () async {
      await repository.register(
        name: 'Siti',
        username: 'siti',
        email: 'siti@mail.com',
        password: 'rahasia123',
      );

      final user = await repository.login(
        identifier: 'siti',
        password: 'rahasia123',
      );

      expect(user.role, UserRole.customer);

      // Password seed tidak berlaku untuk akun baru.
      await expectLater(
        repository.login(identifier: 'siti', password: '123456'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('username duplikat (case-insensitive) -> UsernameTakenFailure',
        () async {
      await expectLater(
        repository.register(
          name: 'X',
          username: 'ADMIN',
          email: 'baru@mail.com',
          password: 'rahasia123',
        ),
        throwsA(isA<UsernameTakenFailure>()),
      );
    });

    test('email duplikat -> EmailTakenFailure', () async {
      await expectLater(
        repository.register(
          name: 'X',
          username: 'userbaru',
          email: 'admin@kantincerdas.com',
          password: 'rahasia123',
        ),
        throwsA(isA<EmailTakenFailure>()),
      );
    });

    test('data tidak valid -> ValidationFailure dengan error per field',
        () async {
      await expectLater(
        repository.register(
          name: 'X',
          username: 'ab',
          email: 'bukan-email',
          password: '123',
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.fieldErrors.keys,
            'fields',
            containsAll(['username', 'email', 'password']),
          ),
        ),
      );
    });
  });

  group('session', () {
    test('restoreSession memulihkan user, logout menghapusnya', () async {
      await repository.login(identifier: 'owner', password: '123456');

      final restored = await repository.restoreSession();
      expect(restored?.username, 'owner');

      await repository.logout();

      expect(await tokenStorage.read(), isNull);
      expect(await repository.restoreSession(), isNull);
    });

    test('restoreSession tanpa token -> null', () async {
      expect(await repository.restoreSession(), isNull);
    });
  });

  group('mapper', () {
    UserModel modelWithRole(String role) => UserModel(
          id: '9',
          username: 'x',
          email: 'x@mail.com',
          name: 'X',
          role: role,
          isActive: true,
        );

    test('role case-insensitive', () {
      expect(modelWithRole('ADMIN').toEntity().role, UserRole.admin);
      expect(modelWithRole('Owner').toEntity().role, UserRole.owner);
    });

    test('role tidak dikenal -> DataParsingException', () {
      expect(
        () => modelWithRole('cashier').toEntity(),
        throwsA(isA<DataParsingException>()),
      );
    });
  });

  group('use case', () {
    test('login: input kosong -> ValidationFailure tanpa memanggil repository',
        () async {
      await expectLater(
        LoginUseCase(repository).execute(identifier: '  ', password: ''),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('register: username & email dinormalisasi ke huruf kecil', () async {
      final user = await RegisterUseCase(repository).execute(
        name: '  Budi  ',
        username: 'Budi.K',
        email: 'Budi@Mail.COM',
        password: 'rahasia123',
      );

      expect(user.username, 'budi.k');
      expect(user.email, 'budi@mail.com');
      expect(user.name, 'Budi');
    });
  });
}

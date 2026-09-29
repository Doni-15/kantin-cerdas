import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_dummy_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/canteen_application_model.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/canteen_application_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/usecases/submit_canteen_application_usecase.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/canteen_application_submit_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_providers.dart';

void main() {
  String? currentUser;
  late CanteenApplicationRepositoryImpl repository;

  setUp(() {
    currentUser = 'user-a';
    repository = CanteenApplicationRepositoryImpl(
      CanteenApplicationDummyDataSource(
        currentUserId: () => currentUser,
        latency: Duration.zero,
      ),
    );
  });

  Future<CanteenApplication> submit({String name = 'Kantin Berkah'}) {
    return SubmitCanteenApplicationUseCase(repository).execute(
      name: name,
      description: 'Kantin sehat',
      address: 'Jl. Mawar 1',
    );
  }

  group('repository (dummy)', () {
    test('belum pernah mengajukan -> null', () async {
      expect(await repository.getMyApplication(), isNull);
    });

    test('submit lalu getMyApplication', () async {
      final created = await submit();

      expect(created.status, CanteenApplicationStatus.submitted);
      expect(created.customerId, 'user-a');

      final mine = await repository.getMyApplication();

      expect(mine?.id, created.id);
      expect(mine?.name, 'Kantin Berkah');
    });

    test('pengajuan terikat per user', () async {
      await submit();

      currentUser = 'user-b';
      expect(await repository.getMyApplication(), isNull);

      currentUser = 'user-a';
      expect(await repository.getMyApplication(), isNotNull);
    });

    test('tanpa login -> Unauthorized', () async {
      currentUser = null;

      await expectLater(
        repository.getMyApplication(),
        throwsA(isA<CanteenApplicationUnauthorizedFailure>()),
      );
      await expectLater(
        submit(),
        throwsA(isA<CanteenApplicationUnauthorizedFailure>()),
      );
    });

    test('updateStatus: disetujui dan ditolak dengan alasan', () async {
      final created = await submit();

      final underReview = await repository.updateStatus(
        id: created.id,
        status: CanteenApplicationStatus.underReview,
      );
      expect(underReview.status, CanteenApplicationStatus.underReview);

      final rejected = await repository.updateStatus(
        id: created.id,
        status: CanteenApplicationStatus.rejected,
        rejectionReason: 'Alamat tidak jelas',
      );
      expect(rejected.status, CanteenApplicationStatus.rejected);
      expect(rejected.rejectionReason, 'Alamat tidak jelas');

      final approved = await repository.updateStatus(
        id: created.id,
        status: CanteenApplicationStatus.approved,
      );
      expect(approved.rejectionReason, isNull);

      final mine = await repository.getMyApplication();
      expect(mine?.status, CanteenApplicationStatus.approved);
    });

    test('updateStatus id tidak dikenal -> UnknownFailure', () async {
      await expectLater(
        repository.updateStatus(
          id: 'tidak-ada',
          status: CanteenApplicationStatus.approved,
        ),
        throwsA(isA<CanteenApplicationUnknownFailure>()),
      );
    });

    test('deleteMyApplication menghapus pengajuan', () async {
      await submit();
      await repository.deleteMyApplication();

      expect(await repository.getMyApplication(), isNull);
    });

    test('skenario offline / timeout -> NetworkFailure', () async {
      await expectLater(
        submit(name: 'offline'),
        throwsA(isA<CanteenApplicationNetworkFailure>()),
      );
      await expectLater(
        submit(name: 'timeout'),
        throwsA(isA<CanteenApplicationNetworkFailure>()),
      );
    });

    test('skenario error500 -> UnknownFailure', () async {
      await expectLater(
        submit(name: 'error500'),
        throwsA(isA<CanteenApplicationUnknownFailure>()),
      );
    });
  });

  group('use case', () {
    test('input kosong atau spasi -> ValidationFailure per field', () async {
      await expectLater(
        SubmitCanteenApplicationUseCase(repository).execute(
          name: '   ',
          description: '',
          address: ' ',
        ),
        throwsA(
          isA<CanteenApplicationValidationFailure>().having(
            (failure) => failure.fieldErrors,
            'fieldErrors',
            {
              'name': 'Nama kantin wajib diisi',
              'description': 'Deskripsi kantin wajib diisi',
              'address': 'Alamat kantin wajib diisi',
            },
          ),
        ),
      );
    });

    test('input di-trim sebelum disimpan', () async {
      final created = await SubmitCanteenApplicationUseCase(repository).execute(
        name: '  Kantin Berkah  ',
        description: ' Sehat ',
        address: ' Jl. Mawar ',
      );

      expect(created.name, 'Kantin Berkah');
      expect(created.description, 'Sehat');
      expect(created.address, 'Jl. Mawar');
    });
  });

  group('model', () {
    Map<String, dynamic> json(String status) => {
          'id': 1,
          'customer_id': 'user-a',
          'name': 'K',
          'description': 'D',
          'address': 'A',
          'status': status,
          'rejection_reason': null,
          'submitted_at': DateTime(2026, 1, 1).toIso8601String(),
        };

    test('status snake_case dan huruf besar dikenali', () {
      expect(
        CanteenApplicationModel.fromJson(json('under_review')).toEntity().status,
        CanteenApplicationStatus.underReview,
      );
      expect(
        CanteenApplicationModel.fromJson(json('APPROVED')).toEntity().status,
        CanteenApplicationStatus.approved,
      );
    });

    test('status tidak dikenal -> DataParsingException', () {
      expect(
        () => CanteenApplicationModel.fromJson(json('cancelled')).toEntity(),
        throwsA(isA<DataParsingException>()),
      );
    });

    test('statusToJson dua arah konsisten', () {
      for (final status in CanteenApplicationStatus.values) {
        final raw = CanteenApplicationModel.statusToJson(status);

        expect(
          CanteenApplicationModel.fromJson(json(raw)).toEntity().status,
          status,
        );
      }
    });
  });

  group('provider', () {
    test('pengajuan ikut akun yang login (ganti akun / logout me-reset)',
        () async {
      late final ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          canteenApplicationDataSourceProvider.overrideWithValue(
            CanteenApplicationDummyDataSource(
              currentUserId: () => container.read(authStateProvider)?.id,
              latency: Duration.zero,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      User user(String id) => User(
            id: id,
            username: 'u$id',
            email: 'u$id@mail.com',
            name: 'User $id',
            role: UserRole.customer,
            isActive: true,
          );

      final auth = container.read(authStateProvider.notifier);

      auth.setUser(user('1'));
      expect(await container.read(canteenApplicationProvider.future), isNull);

      // Tahan provider submit agar tidak ter-dispose di tengah test.
      final subscription = container.listen(
        canteenApplicationSubmitProvider,
        (previous, next) {},
      );

      await container.read(canteenApplicationSubmitProvider.notifier).submit(
            name: 'Kantin Berkah',
            description: 'Kantin sehat',
            address: 'Jl. Mawar 1',
          );

      subscription.close();

      final mine = await container.read(canteenApplicationProvider.future);
      expect(mine?.customerId, '1');

      // Akun lain tidak melihat pengajuan akun pertama.
      auth.setUser(user('2'));
      expect(await container.read(canteenApplicationProvider.future), isNull);

      // Logout: state kosong.
      auth.clearUser();
      expect(await container.read(canteenApplicationProvider.future), isNull);

      // Login kembali sebagai akun pertama: pengajuan muncul lagi.
      auth.setUser(user('1'));
      final again = await container.read(canteenApplicationProvider.future);
      expect(again?.name, 'Kantin Berkah');
    });
  });
}

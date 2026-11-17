import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/admin/data/mappers/admin_failure_mapper.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/canteen_application_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_order_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';
import 'package:kantin_cerdas/features/owner/data/mappers/owner_failure_mapper.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';

import '../support/data_source_stubs.dart';

class _StubCanteenApplicationDataSource
    implements CanteenApplicationDataSource {
  const _StubCanteenApplicationDataSource({
    required this.onGetMy,
    required this.onLookup,
  });

  final Future<CanteenApplicationModel?> Function() onGetMy;
  final Future<CanteenApplicationLookup> Function(String submissionId) onLookup;

  @override
  bool get isSubmissionConfigured => true;

  @override
  Future<CanteenApplicationModel?> getMyApplication() => onGetMy();

  @override
  Future<CanteenApplicationModel> submit(
    PendingCanteenApplication submission,
  ) => throw UnimplementedError();

  @override
  Future<CanteenApplicationLookup> lookupSubmission({
    required String submissionId,
  }) => onLookup(submissionId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pemetaan error backend ke kegagalan domain (PROD-NEW-06, CRIT-01)', () {
    test(
      'proteksi error HTML reverse-proxy (hasBackendErrorCode == false) tidak dianggap definitif atau null (PROD-NEW-06)',
      () async {
        // Error 409 HTML proxy tanpa kode error backend tidak boleh dipetakan ke OwnerConflictFailure
        final proxyConflict = mapOwnerMutationApiException(
          ApiException(type: ApiExceptionType.response, statusCode: 409),
        );
        expect(proxyConflict, isA<OwnerUnconfirmedFailure>());

        // Error 404 HTML proxy pada lookup pengajuan tetap menjadi UnconfirmedFailure
        final appRepo = CanteenApplicationRepositoryImpl(
          dataSource: _StubCanteenApplicationDataSource(
            onGetMy: () async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
            ),
            onLookup: (_) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
              code: 'NOT_FOUND',
            ),
          ),
        );
        await expectLater(
          appRepo.getMyApplication(),
          throwsA(isA<CustomerFeatureInvalidDataFailure>()),
        );
        await expectLater(
          appRepo.lookupSubmission(submissionId: 'sub-404'),
          throwsA(isA<CanteenApplicationUnconfirmedFailure>()),
        );
      },
    );

    test(
      'pemetaan HTTP 429 dan 5xx pada mappers baca menghasilkan *ReadTimeoutFailure dan createOrder memetakan ApiException secara akurat',
      () async {
        for (final statusCode in <int>[429, 500, 502, 503]) {
          final err = ApiException(
            type: ApiExceptionType.response,
            statusCode: statusCode,
          );
          expect(
            mapCustomerReadApiException(err),
            isA<CustomerFeatureReadTimeoutFailure>(),
          );
          expect(
            mapFoodPreferencesReadApiException(err),
            isA<FoodPreferencesReadTimeoutFailure>(),
          );
          expect(mapOwnerReadApiException(err), isA<OwnerReadTimeoutFailure>());
          expect(mapAdminReadApiException(err), isA<AdminReadTimeoutFailure>());
        }

        final draft = OrderDraft(
          stallId: 'stall-1',
          items: [OrderDraftItem(menuId: 'm-1', quantity: 1)],
        );
        final confirmation = CustomerOrderPriceConfirmation(
          draft: draft,
          unitPricesIdr: const {'m-1': 15000},
        );

        final repo404Backend = CustomerOrderRepositoryImpl(
          dataSource: StubCustomerOrderDataSource(
            onCreateOrder: (d, submissionId, c) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
              code: 'STALL_NOT_FOUND',
            ),
          ),
        );
        await expectLater(
          repo404Backend.createOrder(
            draft: draft,
            submissionId: 'sub-404-backend',
            confirmation: confirmation,
          ),
          throwsA(isA<CustomerOrderRejectedFailure>()),
        );

        final repo404Proxy = CustomerOrderRepositoryImpl(
          dataSource: StubCustomerOrderDataSource(
            onCreateOrder: (d, submissionId, c) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
            ),
          ),
        );
        await expectLater(
          repo404Proxy.createOrder(
            draft: draft,
            submissionId: 'sub-404-proxy',
            confirmation: confirmation,
          ),
          throwsA(isA<CustomerOrderUnconfirmedFailure>()),
        );
      },
    );
  });
}

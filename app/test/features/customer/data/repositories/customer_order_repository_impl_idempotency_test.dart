import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_order_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';

import '../../../../support/data_source_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerOrderRepositoryImpl (CRIT-01, LOW-03)', () {
    test(
      'CustomerOrderRepositoryImpl memvalidasi konfirmasi harga dan meneruskan idempotency submissionId',
      () async {
        final draft = OrderDraft(
          stallId: 'stall-1',
          items: [OrderDraftItem(menuId: 'm-1', quantity: 2)],
        );
        final confirmation = CustomerOrderPriceConfirmation(
          draft: draft,
          unitPricesIdr: const {'m-1': 20000},
        );

        String? capturedSubmissionId;
        final repo = CustomerOrderRepositoryImpl(
          dataSource: StubCustomerOrderDataSource(
            onCreateOrder: (d, submissionId, c) async {
              capturedSubmissionId = submissionId;
              return 'ord-created-1';
            },
          ),
        );

        final orderId = await repo.createOrder(
          draft: draft,
          submissionId: 'sub-idempotent-001',
          confirmation: confirmation,
        );
        expect(orderId, 'ord-created-1');
        expect(capturedSubmissionId, 'sub-idempotent-001');

        await expectLater(
          repo.createOrder(
            draft: draft,
            submissionId: '   ',
            confirmation: confirmation,
          ),
          throwsA(isA<CustomerOrderPreSendFailure>()),
        );
      },
    );
  });
}

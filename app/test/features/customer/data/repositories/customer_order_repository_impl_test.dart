import '../../../../support/simulation_harness.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_order_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_api_datasource.dart';

class OrderSource implements CustomerOrderDataSource {
  OrderSource(this.error);
  final Object? error;
  int calls = 0;
  @override
  bool get isCheckoutConfigured => true;
  @override
  Future<String> createOrder({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  }) async {
    calls++;
    if (error != null) {
      throw error!;
    }
    return 'order-test';
  }

  @override
  Future<OrderSubmissionLookup> lookupSubmission({
    required String submissionId,
  }) async => OrderSubmissionLookup(
    customerId: 'customer-1',
    submissionId: submissionId,
    status: OrderSubmissionStatus.pending,
  );
}

void main() {
  final draft = OrderDraft(
    stallId: 's',
    items: [OrderDraftItem(menuId: 'm', quantity: 1)],
  );
  final confirmation = CustomerOrderPriceConfirmation(
    draft: draft,
    unitPricesIdr: {'m': 10000},
  );
  test('configured source returns its ID exactly once', () async {
    final source = OrderSource(null);
    final repo = CustomerOrderRepositoryImpl(dataSource: source);
    expect(
      await repo.createOrder(
        draft: draft,
        submissionId: 'r',
        confirmation: confirmation,
      ),
      'order-test',
    );
    expect(source.calls, 1);
  });
  for (final error in [
    const CustomerOrderRejectedFailure(),
    const CustomerOrderPriceChangedFailure(),
    const CustomerOrderPreSendFailure(),
  ]) {
    test(
      'definitive failure remains definitive: ${error.runtimeType}',
      () async {
        final source = OrderSource(error);
        final repo = CustomerOrderRepositoryImpl(dataSource: source);
        await expectLater(
          repo.createOrder(
            draft: draft,
            submissionId: 'r',
            confirmation: confirmation,
          ),
          throwsA(same(error)),
        );
        expect(source.calls, 1);
      },
    );
  }
  test('unclassified failure is unknown, without automatic retry', () async {
    final source = OrderSource(StateError('lost'));
    final repo = CustomerOrderRepositoryImpl(dataSource: source);
    await expectLater(
      repo.createOrder(
        draft: draft,
        submissionId: 'r',
        confirmation: confirmation,
      ),
      throwsA(isA<CustomerOrderUnconfirmedFailure>()),
    );
    expect(source.calls, 1);
  });
  test('production default stays unconfigured', () async {
    const repo = CustomerOrderRepositoryImpl(
      dataSource: CustomerOrderApiDataSource(),
    );
    expect(repo.isCheckoutConfigured, isFalse);
    await expectLater(
      repo.createOrder(
        draft: draft,
        submissionId: 'r',
        confirmation: confirmation,
      ),
      throwsA(isA<CustomerOrderNotConfiguredFailure>()),
    );
  });
}

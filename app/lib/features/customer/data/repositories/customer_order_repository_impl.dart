import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_order_repository.dart';

final class CustomerOrderRepositoryImpl implements CustomerOrderRepository {
  const CustomerOrderRepositoryImpl({required this.dataSource});
  final CustomerOrderDataSource dataSource;
  @override
  bool get isCheckoutConfigured => dataSource.isCheckoutConfigured;
  @override
  Future<String> createOrder({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  }) async {
    if (!isCheckoutConfigured) {
      throw const CustomerOrderNotConfiguredFailure();
    }
    if (!confirmation.matchesDraft(draft)) {
      throw const CustomerOrderPreSendFailure();
    }
    if (submissionId.trim().isEmpty) {
      throw const CustomerOrderPreSendFailure();
    }
    try {
      final id = await dataSource.createOrder(
        draft: draft,
        submissionId: submissionId,
        confirmation: confirmation,
      );
      if (id.trim().isEmpty) {
        throw const CustomerOrderUnconfirmedFailure();
      }
      return id;
    } on CustomerOrderNotConfiguredFailure {
      rethrow;
    } on CustomerOrderPreSendFailure {
      rethrow;
    } on CustomerOrderForbiddenFailure {
      rethrow;
    } on CustomerOrderRejectedFailure {
      rethrow;
    } on CustomerOrderPriceChangedFailure {
      rethrow;
    } on ApiException catch (error) {
      throw mapCustomerOrderCreateApiException(error);
    } catch (_) {
      // Termasuk ApiException.unexpected dan kegagalan parsing setelah send.
      // Hanya kegagalan eksplisit di atas yang membuktikan pesanan belum dibuat.
      throw const CustomerOrderUnconfirmedFailure();
    }
  }

  @override
  Future<OrderSubmissionLookup> lookupSubmission({
    required String submissionId,
  }) async {
    if (!isCheckoutConfigured) {
      throw const CustomerOrderNotConfiguredFailure();
    }
    if (submissionId.trim().isEmpty) {
      throw const CustomerOrderUnconfirmedFailure();
    }
    try {
      final result = await dataSource.lookupSubmission(
        submissionId: submissionId,
      );
      if (result.submissionId != submissionId) {
        throw const CustomerOrderUnconfirmedFailure();
      }
      return result;
    } on CustomerOrderNotConfiguredFailure {
      rethrow;
    } catch (_) {
      throw const CustomerOrderUnconfirmedFailure();
    }
  }
}

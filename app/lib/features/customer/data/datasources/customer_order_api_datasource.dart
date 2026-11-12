import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_order_models.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';

/// Adapter HTTP untuk pembuatan pesanan pelanggan dan pemeriksaan idempotensi.
final class CustomerOrderApiDataSource implements CustomerOrderDataSource {
  const CustomerOrderApiDataSource({this.dio});

  final Dio? dio;

  @override
  bool get isCheckoutConfigured =>
      dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<String> createOrder({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  }) async {
    final client = dio;
    if (!isCheckoutConfigured || client == null) {
      throw const CustomerOrderNotConfiguredFailure();
    }

    final payload = OrderCreateRequestModel.fromDomain(
      draft: draft,
      submissionId: submissionId,
      confirmation: confirmation,
    );

    try {
      final response = await client.post<Object?>(
        '/v1/customer/orders',
        data: payload.toJson(),
        options: Options(
          headers: <String, Object?>{'Idempotency-Key': submissionId},
          sendTimeout: AppEnvironment.checkoutTimeout,
          receiveTimeout: AppEnvironment.checkoutTimeout,
        ),
      );
      final data = asJsonMap(response.data, fieldName: 'order');
      final orderId = data['order_id'] ?? data['orderId'] ?? data['id'];
      if (orderId is! String || orderId.trim().isEmpty) {
        throw const DataParsingException('ID pesanan kosong pada respons.');
      }
      return orderId;
    } on DioException catch (error) {
      throw mapCustomerOrderCreateApiException(mapDioException(error));
    }
  }

  @override
  Future<OrderSubmissionLookup> lookupSubmission({
    required String submissionId,
  }) async {
    final client = dio;
    if (!isCheckoutConfigured || client == null) {
      throw const CustomerOrderNotConfiguredFailure();
    }

    try {
      final response = await client.get<Object?>(
        '/v1/operations/orders/${Uri.encodeComponent(submissionId)}',
      );
      return OrderSubmissionLookupModel.fromJson(
        asJsonMap(response.data, fieldName: 'order_submission_lookup'),
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

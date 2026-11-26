import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_rpc_helper.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/data/supabase_customer_error_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';

class SupabaseCustomerStore implements CustomerStore {
  const SupabaseCustomerStore(this._factory, {this.httpClient});

  final SupabaseClientFactory _factory;
  final http.Client? httpClient;

  @override
  Future<Map<String, Object?>?> getStallDetail(String stallId) =>
      _rpcNullableObject('kc_customer_get_stall_detail', {
        'p_stall_id': stallId,
      });

  @override
  Future<Map<String, Object?>?> getMenuDetail(String menuId) =>
      _rpcNullableObject('kc_customer_get_menu_detail', {
        'p_menu_id': menuId,
      });

  @override
  Future<String?> getStallPhotoPath(String stallId) => _rpcNullableText(
    'kc_customer_get_stall_photo_path',
    {'p_stall_id': stallId},
  );

  @override
  Future<String?> getMenuPhotoPath(String menuId) => _rpcNullableText(
    'kc_customer_get_menu_photo_path',
    {'p_menu_id': menuId},
  );

  @override
  Future<Map<String, Object?>> getCart(String customerId) =>
      _rpcObject('kc_customer_get_cart', {'p_customer_id': customerId});

  @override
  Future<Map<String, Object?>> addCartItem(
    String customerId, {
    required String menuId,
    required int quantity,
    required String itemNote,
    required bool replaceStall,
  }) => _rpcObject('kc_customer_add_cart_item', {
    'p_customer_id': customerId,
    'p_menu_id': menuId,
    'p_quantity': quantity,
    'p_item_note': itemNote,
    'p_replace_stall': replaceStall,
  });

  @override
  Future<Map<String, Object?>> updateCartItem(
    String customerId, {
    required String itemId,
    required int quantity,
    String? itemNote,
  }) => _rpcObject('kc_customer_update_cart_item', {
    'p_customer_id': customerId,
    'p_item_id': itemId,
    'p_quantity': quantity,
    'p_item_note': itemNote,
  });

  @override
  Future<Map<String, Object?>> setCartNote(
    String customerId, {
    required String generalNote,
  }) => _rpcObject('kc_customer_set_cart_note', {
    'p_customer_id': customerId,
    'p_general_note': generalNote,
  });

  @override
  Future<Map<String, Object?>> acknowledgeCartPrices(
    String customerId, {
    int? expectedVersion,
  }) => _rpcObject('kc_customer_acknowledge_cart_prices', {
    'p_customer_id': customerId,
    'p_expected_version': expectedVersion,
  });

  @override
  Future<Map<String, Object?>> clearCart(String customerId) =>
      _rpcObject('kc_customer_clear_cart', {'p_customer_id': customerId});

  @override
  Future<Map<String, Object?>> createCheckoutAttempt(
    String customerId, {
    required int expectedVersion,
  }) => _rpcObject('kc_customer_create_checkout_attempt', {
    'p_customer_id': customerId,
    'p_expected_version': expectedVersion,
  });

  @override
  Future<Map<String, Object?>?> getOrderByAttempt(
    String customerId, {
    required String attemptId,
  }) => _rpcNullableObject('kc_customer_get_order_by_attempt', {
    'p_customer_id': customerId,
    'p_attempt_id': attemptId,
  });

  @override
  Future<Map<String, Object?>> checkout(
    String customerId, {
    required String customerName,
    required String attemptId,
    required int expectedVersion,
  }) => _rpcObject('kc_customer_checkout', {
    'p_customer_id': customerId,
    'p_customer_name': customerName,
    'p_attempt_id': attemptId,
    'p_expected_version': expectedVersion,
  });

  @override
  Future<Map<String, Object?>> listOrders(
    String customerId, {
    required String scope,
    required int limit,
    required int offset,
  }) => _rpcObject('kc_customer_list_orders', {
    'p_customer_id': customerId,
    'p_scope': scope,
    'p_limit': limit,
    'p_offset': offset,
  });

  @override
  Future<Map<String, Object?>?> getOrder(
    String customerId, {
    required String orderId,
  }) => _rpcNullableObject('kc_customer_get_order', {
    'p_customer_id': customerId,
    'p_order_id': orderId,
  });

  @override
  Future<Map<String, Object?>> cancelOrder(
    String customerId, {
    required String orderId,
  }) => _rpcObject('kc_customer_cancel_order', {
    'p_customer_id': customerId,
    'p_order_id': orderId,
  });

  @override
  Future<Map<String, Object?>> getOwnerApplicationState(String customerId) =>
      _rpcObject('kc_customer_get_owner_application_state', {
        'p_customer_id': customerId,
      });

  @override
  Future<Map<String, Object?>> submitOwnerApplication(
    String customerId, {
    required String plannedStallName,
    required String plannedLocation,
    required String reason,
  }) => _rpcObject('kc_customer_submit_owner_application', {
    'p_customer_id': customerId,
    'p_planned_stall_name': plannedStallName,
    'p_planned_location': plannedLocation,
    'p_reason': reason,
  });

  @override
  Future<Map<String, Object?>> getAdminActiveOrderIndicator(String userId) =>
      _rpcObject('kc_admin_user_active_order_indicator', {
        'p_user_id': userId,
      });

  Future<Map<String, Object?>> _rpcObject(
    String function,
    Map<String, Object?> params,
  ) => runSupabaseRpc(
    factory: _factory,
    httpClient: httpClient,
    fn: function,
    params: params,
    decode: (result) => decodeRpcObject(
      result,
      () => const CustomerFailure(CustomerFailureCode.unavailable),
    ),
    onPostgrestError: mapCustomerPostgrestException,
    onUnavailable: () => const CustomerFailure(CustomerFailureCode.unavailable),
  );

  Future<Map<String, Object?>?> _rpcNullableObject(
    String function,
    Map<String, Object?> params,
  ) => runSupabaseRpc(
    factory: _factory,
    httpClient: httpClient,
    fn: function,
    params: params,
    decode: (result) => decodeRpcNullableObject(
      result,
      () => const CustomerFailure(CustomerFailureCode.unavailable),
    ),
    onPostgrestError: mapCustomerPostgrestException,
    onUnavailable: () => const CustomerFailure(CustomerFailureCode.unavailable),
  );

  Future<String?> _rpcNullableText(
    String function,
    Map<String, Object?> params,
  ) => runSupabaseRpc(
    factory: _factory,
    httpClient: httpClient,
    fn: function,
    params: params,
    decode: (result) => decodeRpcNullableText(
      result,
      () => const CustomerFailure(CustomerFailureCode.unavailable),
    ),
    onPostgrestError: mapCustomerPostgrestException,
    onUnavailable: () => const CustomerFailure(CustomerFailureCode.unavailable),
  );
}

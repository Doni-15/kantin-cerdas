import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_validator.dart';

typedef JsonMap = Map<String, Object?>;

final class CustomerOrdersService {
  const CustomerOrdersService(this.supabase);

  final SupabaseService supabase;

  Future<JsonMap> getOrders(
    AuthenticatedActor actor,
    ValidatedListQuery input,
  ) async {
    _requireCustomer(actor);

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_list_customer_orders',
      params: {
        'p_actor_id': actor.id,
        'p_history': input.history,
        'p_cursor_ts': input.cursorTs?.toUtc().toIso8601String(),
        'p_cursor_id': input.cursorId,
        'p_limit': input.limit,
      },
    );
    return _jsonMapResult(result, 'rpc_list_customer_orders');
  }

  Future<JsonMap> getOrderDetail(
    AuthenticatedActor actor,
    String orderId,
  ) async {
    _requireCustomer(actor);

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_get_customer_order',
      params: {'p_actor_id': actor.id, 'p_order_id': orderId},
    );
    if (result == null) {
      throw ApiException.notFound(
        'Pesanan tidak ditemukan.',
        'ORDER_NOT_FOUND',
      );
    }
    return _jsonMapResult(result, 'rpc_get_customer_order');
  }

  Future<void> cancelOrder(
    AuthenticatedActor actor,
    String orderId,
    ValidatedCancelInput input,
  ) async {
    _requireCustomer(actor);

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_cancel_customer_order',
      params: {
        'p_actor_id': actor.id,
        'p_mutation_id': input.mutationId,
        'p_order_id': orderId,
        'p_expected_version': input.expectedVersion,
      },
    );
    _jsonMapResult(result, 'rpc_cancel_customer_order');
  }

  void _requireCustomer(AuthenticatedActor actor) {
    if (actor.role != 'customer') {
      throw ApiException.forbidden(
        'Endpoint ini hanya dapat digunakan oleh pelanggan.',
        'FORBIDDEN_ROLE',
      );
    }
  }

  JsonMap _jsonMapResult(dynamic result, String rpcName) {
    if (result is! Map) {
      throw ApiException(
        statusCode: 500,
        code: 'INVALID_RPC_RESPONSE',
        message: 'Respons $rpcName dari database tidak valid.',
      );
    }
    return JsonMap.from(result);
  }
}

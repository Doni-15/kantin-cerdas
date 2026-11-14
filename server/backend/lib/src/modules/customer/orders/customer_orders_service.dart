import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/core/utils/json_types.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_validator.dart';

final class CustomerOrdersService {
  const CustomerOrdersService(this.supabase);

  final SupabaseService supabase;

  static const Set<String> _allowedCustomerFeatureRoles = <String>{
    'customer',
    'owner',
  };

  Future<JsonMap> createOrder(
    AuthenticatedActor actor,
    ValidatedCreateOrderInput input,
  ) async {
    _requireCustomerFeatureRole(actor);

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_create_customer_order',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_submission_id': input.submissionId,
        'p_stall_id': input.stallId,
        'p_items': input.items,
        'p_total_price_idr': input.totalPriceIdr,
        'p_order_note': input.orderNote,
      },
    );
    return asDatabaseMap(result, 'rpc_create_customer_order');
  }

  /// FE-BE-MED-02: Meneruskan `input.cursorTsIso` (string ISO-8601 tervalidasi)
  /// secara langsung ke `p_cursor_ts` tanpa konversi ulang `.toIso8601String()`.
  Future<JsonMap> getOrders(
    AuthenticatedActor actor,
    ValidatedListQuery input,
  ) async {
    _requireCustomerFeatureRole(actor);

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_list_customer_orders',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_history': input.history,
        'p_cursor_ts': input.cursorTsIso,
        'p_cursor_id': input.cursorId,
        'p_limit': input.limit,
      },
    );
    return asDatabaseMap(result, 'rpc_list_customer_orders');
  }

  Future<JsonMap> getOrderDetail(
    AuthenticatedActor actor,
    String orderId,
  ) async {
    _requireCustomerFeatureRole(actor);

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_get_customer_order',
      params: <String, Object?>{'p_actor_id': actor.id, 'p_order_id': orderId},
    );
    if (result == null) {
      throw ApiException.notFound(
        'Pesanan tidak ditemukan.',
        'ORDER_NOT_FOUND',
      );
    }
    return asDatabaseMap(result, 'rpc_get_customer_order');
  }

  /// FE-BE-HIGH-02: Mengembalikan langsung snapshot JSONB dari
  /// `rpc_cancel_customer_order` tanpa memanggil `rpc_get_customer_order` kedua kalinya.
  Future<JsonMap> cancelOrder(
    AuthenticatedActor actor,
    String orderId,
    ValidatedCancelInput input,
  ) async {
    _requireCustomerFeatureRole(actor);

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_cancel_customer_order',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_mutation_id': input.mutationId,
        'p_order_id': orderId,
        'p_expected_version': input.expectedVersion,
      },
    );
    return asDatabaseMap(result, 'rpc_cancel_customer_order');
  }

  void _requireCustomerFeatureRole(AuthenticatedActor actor) {
    if (!_allowedCustomerFeatureRoles.contains(actor.role)) {
      throw ApiException.forbidden(
        'Endpoint ini hanya dapat digunakan oleh pelanggan atau pemilik kantin.',
        'FORBIDDEN',
      );
    }
  }
}

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/core/utils/json_types.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_validator.dart';

final class CustomerOrdersService {
  const CustomerOrdersService(this.supabase);

  final SupabaseService supabase;

  /// Sesuai aturan domain (`UserRole.canUseCustomerFeatures` di aplikasi dan
  /// `ARRAY['customer', 'owner']` di SQL `006` & `009`), pemilik kantin (`owner`)
  /// tetap memiliki hak sebagai pelanggan untuk pesanan pribadinya sendiri.
  static const Set<String> _allowedCustomerFeatureRoles = <String>{
    'customer',
    'owner',
  };

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
    asDatabaseMap(result, 'rpc_cancel_customer_order');
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

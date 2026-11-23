import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_rpc_helper.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/data/supabase_admin_error_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_store.dart';

class SupabaseAdminStore implements AdminStore {
  const SupabaseAdminStore(this._factory, {this._httpClient});

  final SupabaseClientFactory _factory;
  final http.Client? _httpClient;

  @override
  Future<Map<String, Object?>> getDashboard(String adminId) =>
      _rpcObject('kc_admin_dashboard', {'p_admin_id': adminId});

  @override
  Future<Map<String, Object?>> listApplications(
    String adminId, {
    required String scope,
    required int limit,
    required int offset,
  }) => _rpcObject('kc_admin_list_applications', {
    'p_admin_id': adminId,
    'p_scope': scope,
    'p_limit': limit,
    'p_offset': offset,
  });

  @override
  Future<Map<String, Object?>> getApplication(
    String adminId, {
    required String applicationId,
  }) => _rpcObject('kc_admin_get_application', {
    'p_admin_id': adminId,
    'p_application_id': applicationId,
  });

  @override
  Future<Map<String, Object?>> reviewApplication(
    String adminId, {
    required String applicationId,
    required String decision,
    String? rejectionReason,
  }) => _rpcObject('kc_admin_review_application', {
    'p_admin_id': adminId,
    'p_application_id': applicationId,
    'p_decision': decision,
    'p_rejection_reason': rejectionReason,
  });

  @override
  Future<Map<String, Object?>> listUsers(
    String adminId, {
    String? role,
    String? status,
    String? query,
    required int limit,
    required int offset,
  }) => _rpcObject('kc_admin_list_users', {
    'p_admin_id': adminId,
    'p_role': role,
    'p_status': status,
    'p_query': query,
    'p_limit': limit,
    'p_offset': offset,
  });

  @override
  Future<Map<String, Object?>> getUser(
    String adminId, {
    required String userId,
  }) => _rpcObject('kc_admin_get_user', {
    'p_admin_id': adminId,
    'p_user_id': userId,
  });

  @override
  Future<Map<String, Object?>> setUserActiveStatus(
    String adminId, {
    required String targetUserId,
    required bool isActive,
    String? reason,
  }) => _rpcObject('kc_admin_set_user_active_status', {
    'p_admin_id': adminId,
    'p_target_user_id': targetUserId,
    'p_is_active': isActive,
    'p_reason': reason,
  });

  @override
  Future<Map<String, Object?>> listStalls(
    String adminId, {
    String? query,
    required int limit,
    required int offset,
  }) => _rpcObject('kc_admin_list_stalls', {
    'p_admin_id': adminId,
    'p_query': query,
    'p_limit': limit,
    'p_offset': offset,
  });

  @override
  Future<Map<String, Object?>> getStall(
    String adminId, {
    required String stallId,
  }) => _rpcObject('kc_admin_get_stall', {
    'p_admin_id': adminId,
    'p_stall_id': stallId,
  });

  @override
  Future<String?> getStallPhotoPath(
    String adminId, {
    required String stallId,
  }) => _rpcNullableText('kc_admin_get_stall_photo_path', {
    'p_admin_id': adminId,
    'p_stall_id': stallId,
  });

  @override
  Future<Map<String, Object?>> listActionLogs(
    String adminId, {
    String? targetUserId,
    required int limit,
    required int offset,
  }) => _rpcObject('kc_admin_list_action_logs', {
    'p_admin_id': adminId,
    'p_target_user_id': targetUserId,
    'p_limit': limit,
    'p_offset': offset,
  });

  Future<Map<String, Object?>> _rpcObject(
    String fn,
    Map<String, Object?> params,
  ) => _call(
    fn,
    params,
    (result) => decodeRpcObject(
      result,
      () => const AdminFailure(AdminFailureCode.unavailable),
    ),
  );

  Future<String?> _rpcNullableText(String fn, Map<String, Object?> params) =>
      _call(
        fn,
        params,
        (result) => decodeRpcNullableText(
          result,
          () => const AdminFailure(AdminFailureCode.unavailable),
        ),
      );

  Future<T> _call<T>(
    String fn,
    Map<String, Object?> params,
    T Function(dynamic) decode,
  ) => runSupabaseRpc(
    factory: _factory,
    httpClient: _httpClient,
    fn: fn,
    params: params,
    decode: decode,
    onPostgrestError: mapAdminPostgrestException,
    onUnavailable: () => const AdminFailure(AdminFailureCode.unavailable),
  );
}

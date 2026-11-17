import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/admin_validated_input.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';

typedef JsonMap = Map<String, Object?>;

/// Layanan bisnis domain Administrasi (`/v1/admin/*`).
///
/// Seluruh pembacaan dan mutasi didelegasikan ke RPC PostgreSQL di
/// `008_rpc_admin.sql` dan `009_read_functions.sql`.
final class AdminService {
  final SupabaseService supabase;

  const AdminService({required this.supabase});

  /// 1. `GET /v1/admin/summary` -> `public.rpc_get_admin_summary`
  Future<JsonMap> getSummary(AuthenticatedActor actor) async {
    final rpcResult = await supabase.adminClient.rpc<dynamic>(
      'rpc_get_admin_summary',
      params: <String, Object?>{'p_actor_id': actor.id},
    );

    if (rpcResult is! Map) {
      throw const ApiException(
        statusCode: 500,
        code: 'DATABASE_ERROR',
        message: 'Format ringkasan admin dari database tidak valid.',
      );
    }
    return JsonMap.from(rpcResult);
  }

  /// 2. `GET /v1/admin/users` -> `public.rpc_list_admin_users`
  Future<JsonMap> listUsers({
    required AuthenticatedActor actor,
    required ValidatedListAdminUsersInput input,
  }) async {
    final rpcResult = await supabase.adminClient.rpc<dynamic>(
      'rpc_list_admin_users',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_search': input.search,
        'p_cursor_ts': input.cursor?.cursorTsIso,
        'p_cursor_id': input.cursor?.cursorId,
        'p_limit': input.limit,
      },
    );

    if (rpcResult is! Map) {
      throw const ApiException(
        statusCode: 500,
        code: 'DATABASE_ERROR',
        message: 'Format daftar pengguna dari database tidak valid.',
      );
    }
    return JsonMap.from(rpcResult);
  }

  /// 3. `GET /v1/admin/users/<userId>` -> `public.rpc_get_admin_user`
  /// Mengembalikan `null` apabila pengguna tidak ditemukan.
  Future<JsonMap?> getUser({
    required AuthenticatedActor actor,
    required String targetUserId,
  }) async {
    final rpcResult = await supabase.adminClient.rpc<dynamic>(
      'rpc_get_admin_user',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_target_user_id': targetUserId,
      },
    );

    if (rpcResult == null) {
      return null;
    }
    if (rpcResult is! Map) {
      throw const ApiException(
        statusCode: 500,
        code: 'DATABASE_ERROR',
        message: 'Format detail pengguna dari database tidak valid.',
      );
    }
    return JsonMap.from(rpcResult);
  }

  /// 4. `POST /v1/admin/users/<userId>/access` -> `public.rpc_admin_set_user_access`
  ///
  /// Catatan Keamanan: RPC di `008_rpc_admin.sql` mengembalikan `user`, `version`,
  /// `auth_uid`, dan `session_epoch`. Kita hanya meneruskan `user` dan `version`
  /// ke klien sesuai kontrak `AdminUserRecordModel` agar `auth_uid` internal
  /// tidak terekspos ke luar server.
  Future<JsonMap> setUserAccess({
    required AuthenticatedActor actor,
    required ValidatedSetUserAccessInput input,
  }) async {
    final rpcResult = await supabase.adminClient.rpc<dynamic>(
      'rpc_admin_set_user_access',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_mutation_id': input.mutationId,
        'p_target_user_id': input.targetUserId,
        'p_expected_version': input.expectedVersion,
        'p_is_active': input.isActive,
        'p_reason': input.reason,
      },
    );

    if (rpcResult is! Map) {
      throw const ApiException(
        statusCode: 500,
        code: 'DATABASE_ERROR',
        message: 'Respons perubahan akses pengguna dari database tidak valid.',
      );
    }

    final map = JsonMap.from(rpcResult);
    return <String, Object?>{'user': map['user'], 'version': map['version']};
  }

  /// 5. `GET /v1/admin/applications` -> `public.rpc_list_admin_applications`
  Future<JsonMap> listApplications({
    required AuthenticatedActor actor,
    required ValidatedListAdminApplicationsInput input,
  }) async {
    final rpcResult = await supabase.adminClient.rpc<dynamic>(
      'rpc_list_admin_applications',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_status': input.status,
        'p_cursor_ts': input.cursor?.cursorTsIso,
        'p_cursor_id': input.cursor?.cursorId,
        'p_limit': input.limit,
      },
    );

    if (rpcResult is! Map) {
      throw const ApiException(
        statusCode: 500,
        code: 'DATABASE_ERROR',
        message: 'Format daftar pengajuan stan dari database tidak valid.',
      );
    }
    return JsonMap.from(rpcResult);
  }

  /// 6. `GET /v1/admin/applications/<applicationId>` -> `public.rpc_get_admin_application`
  /// Mengembalikan `null` apabila pengajuan tidak ditemukan.
  Future<JsonMap?> getApplication({
    required AuthenticatedActor actor,
    required String applicationId,
  }) async {
    final rpcResult = await supabase.adminClient.rpc<dynamic>(
      'rpc_get_admin_application',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_application_id': applicationId,
      },
    );

    if (rpcResult == null) {
      return null;
    }
    if (rpcResult is! Map) {
      throw const ApiException(
        statusCode: 500,
        code: 'DATABASE_ERROR',
        message: 'Format detail pengajuan stan dari database tidak valid.',
      );
    }
    return JsonMap.from(rpcResult);
  }

  /// 7. `POST /v1/admin/applications/<applicationId>/review` -> `public.rpc_admin_review_application`
  Future<JsonMap> reviewApplication({
    required AuthenticatedActor actor,
    required ValidatedReviewApplicationInput input,
  }) async {
    final rpcResult = await supabase.adminClient.rpc<dynamic>(
      'rpc_admin_review_application',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_mutation_id': input.mutationId,
        'p_application_id': input.applicationId,
        'p_expected_version': input.expectedVersion,
        'p_decision': input.decision,
        'p_reason': input.reason,
      },
    );

    if (rpcResult is! Map) {
      throw const ApiException(
        statusCode: 500,
        code: 'DATABASE_ERROR',
        message: 'Respons peninjauan pengajuan stan dari database tidak valid.',
      );
    }
    return JsonMap.from(rpcResult);
  }
}

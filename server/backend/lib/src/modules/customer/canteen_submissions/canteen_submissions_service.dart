import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/core/utils/json_types.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/canteen_submissions/canteen_submissions_validated_input.dart';

/// Layanan bisnis pengajuan pembukaan stan kantin (`/v1/customer/canteen-applications`).
///
/// Seluruh pembacaan dan mutasi didelegasikan ke RPC PostgreSQL di
/// `006_rpc_customer.sql` (`rpc_submit_canteen_application`) dan
/// `009_read_functions.sql` (`rpc_get_my_canteen_application`).
final class CanteenSubmissionsService {
  const CanteenSubmissionsService({required this.supabase});

  final SupabaseService supabase;

  static const Set<String> _readRoles = <String>{'customer', 'owner'};

  /// 1. `GET /v1/customer/canteen-applications/me` -> `public.rpc_get_my_canteen_application`
  /// Mengembalikan `null` apabila akun belum pernah mengajukan pembukaan stan.
  Future<JsonMap?> getMyApplication(AuthenticatedActor actor) async {
    if (!_readRoles.contains(actor.role)) {
      throw ApiException.forbidden(
        'Pengajuan stan hanya dapat dilihat oleh pelanggan atau pemilik kantin.',
        'FORBIDDEN',
      );
    }

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_get_my_canteen_application',
      params: <String, Object?>{'p_actor_id': actor.id},
    );
    if (result == null) {
      return null;
    }
    return asDatabaseMap(result, 'rpc_get_my_canteen_application');
  }

  /// 2. `POST /v1/customer/canteen-applications` -> `public.rpc_submit_canteen_application`
  /// Hanya pengguna dengan role `customer` yang diizinkan mengirim pengajuan baru
  /// atau mengajukan ulang pengajuan yang berstatus `rejected`.
  Future<JsonMap> submitApplication(
    AuthenticatedActor actor,
    ValidatedSubmitCanteenApplicationInput input,
  ) async {
    if (actor.role != 'customer') {
      throw ApiException.forbidden(
        'Hanya pelanggan yang dapat mengajukan pembukaan stan baru.',
        'FORBIDDEN',
      );
    }

    final result = await supabase.adminClient.rpc<dynamic>(
      'rpc_submit_canteen_application',
      params: <String, Object?>{
        'p_actor_id': actor.id,
        'p_submission_id': input.submissionId,
        'p_name': input.name,
        'p_description': input.description,
        'p_location': input.location,
        'p_phone': input.phone,
        'p_previous_id': input.previousId,
        'p_previous_version': input.previousVersion,
      },
    );
    return asDatabaseMap(result, 'rpc_submit_canteen_application');
  }
}

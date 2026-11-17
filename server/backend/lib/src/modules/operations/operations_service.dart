import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/core/utils/json_types.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';
import 'package:kantin_cerdas_backend/src/modules/operations/operations_validator.dart';

/// Layanan pemulihan status mutasi terjurnal (`GET /v1/operations/<family>/<requestId>`).
///
/// Memanggil `public.rpc_lookup_or_seal_receipt` di `005_idempotency.sql`.
final class OperationsService {
  final SupabaseService supabase;

  const OperationsService({required this.supabase});

  Future<JsonMap> lookupOrSeal({
    required AuthenticatedActor actor,
    required ValidatedOperationLookupInput input,
  }) async {
    final rpcResult = await supabase.adminClient.rpc<dynamic>(
      'rpc_lookup_or_seal_receipt',
      params: <String, Object?>{
        'p_family': input.family,
        'p_request_id': input.requestId,
        'p_actor_id': actor.id,
        'p_fallback_lookup': null,
      },
    );
    return asDatabaseMap(rpcResult, 'respons pemulihan mutasi');
  }
}

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:kantin_cerdas_backend/src/core/middleware/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/operations/operations_service.dart';
import 'package:kantin_cerdas_backend/src/modules/operations/operations_validator.dart';

/// Handler pemulihan mutasi terjurnal (`GET /v1/operations/<family>/<requestId>`).
Handler buildOperationsRouter({
  required AuthService authService,
  required OperationsService operationsService,
}) {
  final router = Router();

  router.get('/<family>/<requestId>', (Request request) async {
    final input = OperationsValidator.validateLookup(
      rawFamily: request.params['family'],
      rawRequestId: request.params['requestId'],
    );

    final result = await operationsService.lookupOrSeal(
      actor: request.authActor,
      input: input,
    );

    return Response.ok(
      jsonEncode(result),
      headers: const <String, String>{
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    );
  });

  return const Pipeline()
      .addMiddleware(authGuard(authService))
      .addHandler(router.call);
}

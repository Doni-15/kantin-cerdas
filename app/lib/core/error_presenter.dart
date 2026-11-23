import 'package:kantin_cerdas/core/error/app_failure.dart';

const authSessionRecoveryFallbackMessage =
    'Terjadi kesalahan saat memulihkan sesi. Coba lagi.';
const catalogLoadFallbackMessage = 'Katalog belum dapat dimuat.';

String presentAppError(Object? error, {required String fallback}) =>
    switch (error) {
      AppFailure(:final message) => message,
      _ => fallback,
    };

String presentAuthError(
  Object? error, {
  String fallback = authSessionRecoveryFallbackMessage,
}) => presentAppError(error, fallback: fallback);

String presentCatalogError(
  Object? error, {
  String fallback = catalogLoadFallbackMessage,
}) => presentAppError(error, fallback: fallback);

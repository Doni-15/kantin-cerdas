import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:supabase/supabase.dart';

final class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, String>? fieldErrors;
  final Map<String, Object?>? details;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fieldErrors,
    this.details,
  });

  factory ApiException.badRequest(
    String message, {
    String code = 'INVALID_INPUT',
    Map<String, String>? fieldErrors,
  }) => ApiException(
    statusCode: 400,
    code: code,
    message: message,
    fieldErrors: fieldErrors,
  );

  factory ApiException.unprocessable(
    String message, {
    String code = 'INVALID_INPUT',
    Map<String, String>? fieldErrors,
  }) => ApiException(
    statusCode: 422,
    code: code,
    message: message,
    fieldErrors: fieldErrors,
  );

  factory ApiException.unauthenticated([
    String message = 'Sesi tidak valid atau telah berakhir. Silakan login kembali.',
    String code = 'UNAUTHENTICATED',
  ]) => ApiException(statusCode: 401, code: code, message: message);

  factory ApiException.forbidden([
    String message = 'Anda tidak memiliki akses untuk menjalankan operasi ini.',
    String code = 'FORBIDDEN',
  ]) => ApiException(statusCode: 403, code: code, message: message);

  factory ApiException.notFound([
    String message = 'Data yang diminta tidak ditemukan.',
    String code = 'NOT_FOUND',
  ]) => ApiException(statusCode: 404, code: code, message: message);

  factory ApiException.conflict({
    required String code,
    required String message,
    Map<String, String>? fieldErrors,
  }) => ApiException(
    statusCode: 409,
    code: code,
    message: message,
    fieldErrors: fieldErrors,
  );

  factory ApiException.rateLimited([
    String message = 'Terlalu banyak permintaan. Silakan coba beberapa saat lagi.',
  ]) => ApiException(
    statusCode: 429,
    code: 'RATE_LIMITED',
    message: message,
  );

  /// Mengubah exception menjadi HTTP [Response] Shelf berformat JSON kontrak.
  Response toResponse({String? requestId}) {
    final payload = <String, Object?>{
      'code': code,
      'message': message,
      if (requestId != null && requestId.isNotEmpty) 
        'request_id': requestId,

      if (fieldErrors != null && fieldErrors!.isNotEmpty)
        'field_errors': fieldErrors,

      if (details != null && details!.isNotEmpty) 
        'details': details,
    };

    return Response(
      statusCode,
      body: jsonEncode(payload),
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
        if (requestId != null && requestId.isNotEmpty)
          'x-request-id': requestId,
      },
    );
  }

  static ApiException fromPostgrest(PostgrestException error) {
    final rawMessage = error.message.trim();
    final sqlState = (error.code ?? '').trim();

    if (rawMessage.contains('USERNAME_TAKEN:')) {
      final clean = rawMessage.split('USERNAME_TAKEN:').last.trim();
      return ApiException.conflict(
        code: 'USERNAME_TAKEN',
        message: clean.isEmpty ? 'Username sudah digunakan.' : clean,
        fieldErrors: const {'username': 'Username sudah digunakan.'},
      );
    }

    if (rawMessage.contains('EMAIL_TAKEN:')) {
      final clean = rawMessage.split('EMAIL_TAKEN:').last.trim();
      return ApiException.conflict(
        code: 'EMAIL_TAKEN',
        message: clean.isEmpty ? 'Email sudah digunakan.' : clean,
        fieldErrors: const {'email': 'Email sudah digunakan.'},
      );
    }

    String extractedCode = '';
    String cleanMessage = rawMessage;
    final colonIndex = rawMessage.indexOf(':');
    if (colonIndex > 0) {
      final candidate = rawMessage.substring(0, colonIndex).trim();
      if (RegExp(r'^[A-Z0-9_]+$').hasMatch(candidate)) {
        extractedCode = candidate;
        cleanMessage = rawMessage.substring(colonIndex + 1).trim();
      }
    }

    switch (sqlState) {
      case 'KC001':
        return ApiException(
          statusCode: 401,
          code: extractedCode.isNotEmpty ? extractedCode : 'UNAUTHENTICATED',
          message: cleanMessage,
        );

      case 'KC002':
        return ApiException(
          statusCode: 403,
          code: extractedCode.isNotEmpty ? extractedCode : 'FORBIDDEN',
          message: cleanMessage,
        );

      case 'KC003':
        return ApiException(
          statusCode: 403,
          code: 'ACCOUNT_DISABLED',
          message: cleanMessage,
        );

      case 'KC004': case 'KC005': case 'KC006': case 'KC007': 
      case 'KC008': case 'KC009': case 'KC010': case 'KC011':
        return ApiException(
          statusCode: 422,
          code: extractedCode.isNotEmpty ? extractedCode : 'INVALID_INPUT',
          message: cleanMessage,
        );

      case 'KC012':
        return ApiException(
          statusCode: 404,
          code: 'STALL_NOT_FOUND',
          message: cleanMessage,
        );

      case 'KC013':
        return ApiException(
          statusCode: 409,
          code: 'STALL_CLOSED',
          message: cleanMessage,
        );

      case 'KC014':
        return ApiException(
          statusCode: 409,
          code: 'MENU_UNAVAILABLE',
          message: cleanMessage,
        );

      case 'KC015':
        return ApiException(
          statusCode: 409,
          code: 'PRICE_CHANGED',
          message: cleanMessage,
        );

      case 'KC016':
        return ApiException(
          statusCode: 404,
          code: 'NO_STALL',
          message: cleanMessage,
        );

      case 'KC017': case 'KC018': case 'KC019': case 'KC020': case 'KC021': case 'KC022':
        return ApiException(
          statusCode: 409,
          code: extractedCode.isNotEmpty ? extractedCode : 'VERSION_CONFLICT',
          message: cleanMessage,
        );

      default:
        return const ApiException(
          statusCode: 500,
          code: 'DATABASE_ERROR',
          message: 'Terjadi kesalahan pada server saat memproses data.',
        );
    }
  }

  static ApiException fromSupabaseAuth(AuthException error) {
    final lower = error.message.toLowerCase();
    final code = (error.code ?? '').toLowerCase();

    if (code == 'invalid_credentials' || lower.contains('invalid login credentials')) {
      return const ApiException(
        statusCode: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Username/email atau password salah.',
      );
    }

    if (code == 'user_already_exists' || code == 'email_exists' ||
      lower.contains('already registered') || lower.contains('already been registered')
    ) {
      return ApiException.conflict(
        code: 'EMAIL_TAKEN',
        message: 'Email sudah digunakan.',
        fieldErrors: const {'email': 'Email sudah digunakan.'},
      );
    }

    if (code == 'weak_password' ||
      lower.contains('weak password') ||
      lower.contains('password should be')) {
      return ApiException.unprocessable(
        'Password terlalu lemah. Gunakan kombinasi yang lebih kuat.',
        code: 'WEAK_PASSWORD',
        fieldErrors: const {'password': 'Password terlalu lemah.'},
      );
    }

    if (code == 'over_request_rate_limit' || error.statusCode == '429') {
      return ApiException.rateLimited();
    }

    if (lower.contains('expired') || code == 'bad_jwt') {
      return ApiException.unauthenticated(
        'Sesi Anda telah berakhir. Silakan login kembali.',
        'TOKEN_EXPIRED',
      );
    }

    return ApiException.unauthenticated(
      'Autentikasi gagal. Silakan login kembali.',
      'UNAUTHENTICATED',
    );
  }
}
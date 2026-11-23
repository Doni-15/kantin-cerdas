import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:supabase/supabase.dart';

typedef SignupFailureReporter = void Function(String code, int? status);

const _signupProviderCodes = {
  'captcha_failed',
  'conflict',
  'email_address_invalid',
  'email_address_not_authorized',
  'email_provider_disabled',
  'hook_timeout',
  'hook_timeout_after_retry',
  'over_email_send_rate_limit',
  'over_request_rate_limit',
  'request_timeout',
  'signup_disabled',
  'unexpected_failure',
  'validation_failed',
  'weak_password',
};

const _rejectedProviderCodes = {
  'invalid_credentials',
  'bad_jwt',
  'otp_expired',
  'refresh_token_not_found',
  'refresh_token_already_used',
  'bad_code_verifier',
  'flow_state_expired',
  'flow_state_not_found',
  'session_not_found',
  'session_expired',
  'user_not_found',
  'user_banned',
  'validation_failed',
};

bool couldBeConcurrentRegistration(AuthException error) {
  if (error.statusCode != '500') return false;
  const code = 'unexpected_failure';
  const message = 'Database error saving new user';
  if (error.code != null) {
    return error.code == code && error.message == message;
  }
  // GoTrue's Dart SDK keeps the raw 5xx body in the retryable error.
  if (error is! AuthRetryableFetchException || error.message.length > 4096) {
    return false;
  }
  try {
    final body = jsonDecode(error.message);
    return body is Map<String, dynamic> &&
        (body['code'] ?? body['error_code']) == code &&
        (body['message'] ?? body['msg']) == message;
  } on FormatException {
    return false;
  }
}

Future<T> invokeSupabaseAuth<T>(
  Future<T> Function() operation, {
  AuthFailure? rejected,
  bool isSignup = false,
  SignupFailureReporter? onSignupFailure,
}) async {
  final report = isSignup ? onSignupFailure : null;
  try {
    return await operation();
  } on AuthException catch (error) {
    final status = int.tryParse(error.statusCode ?? '');
    final code = error.code ?? '';
    report?.call(
      _signupProviderCodes.contains(code) ? code : 'provider_error',
      status,
    );
    if (status == 429 || code.startsWith('over_')) {
      throw AuthFailure.rateLimited;
    }
    if (status != null && status >= 500) throw AuthFailure.unavailable;
    if (code == 'email_not_confirmed') throw AuthFailure.emailNotVerified;
    if (code == 'user_banned' && rejected != AuthFailure.invalidCredentials) {
      throw AuthFailure.inactiveAccount;
    }
    if (code == 'weak_password') throw AuthFailure.weakPassword;
    if (code == 'same_password') throw AuthFailure.samePassword;
    if (rejected == AuthFailure.invalidCredentials &&
        (code == 'email_exists' || code == 'user_already_exists')) {
      throw AuthFailure.emailUnavailable;
    }
    if (isSignup) {
      switch (code) {
        case 'email_address_invalid':
          throw AuthFailure.signupEmailInvalid;
        case 'email_address_not_authorized':
          throw AuthFailure.signupEmailDeliveryRestricted;
        case 'validation_failed' when status == 400 || status == 422:
          throw AuthFailure.invalidInput;
      }
    }
    if (rejected != null &&
        (_rejectedProviderCodes.contains(code) ||
            (code.isEmpty &&
                (status == 400 || status == 401 || status == 403)))) {
      throw rejected;
    }
    throw AuthFailure.unavailable;
  } on PostgrestException {
    throw AuthFailure.unavailable;
  } on TimeoutException {
    report?.call('timeout', null);
    throw AuthFailure.unavailable;
  } on SocketException {
    report?.call('network_error', null);
    throw AuthFailure.unavailable;
  } on http.ClientException {
    report?.call('network_error', null);
    throw AuthFailure.unavailable;
  } on FormatException {
    report?.call('invalid_response', null);
    throw AuthFailure.unavailable;
  }
}

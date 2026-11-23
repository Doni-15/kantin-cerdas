import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:web/web.dart' as web;

Future<T> runWebSessionLock<T>(Future<T> Function() operation) async {
  final navigator = web.window.navigator;
  if (!navigator.hasProperty('locks'.toJS).toDart) {
    throw const AuthException(
      'WEB_SESSION_UNSUPPORTED',
      'Sesi aman memerlukan browser terbaru dan koneksi HTTPS.',
    );
  }

  late T value;
  Object? failure;
  StackTrace? trace;
  Future<JSAny?> locked() async {
    try {
      value = await operation();
    } catch (error, stack) {
      failure = error;
      trace = stack;
    }
    return null;
  }

  await navigator.locks
      .request('kantin-cerdas-web-session-v1', (() => locked().toJS).toJS)
      .toDart;
  if (failure != null) Error.throwWithStackTrace(failure!, trace!);
  return value;
}

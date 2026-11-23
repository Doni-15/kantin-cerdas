import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth_protocol.dart';
import 'package:url_launcher/url_launcher.dart';

Future<Uri> openGoogleBrowser({
  required Uri Function(Uri) authorize,
  required String state,
  required Future<void> cancelled,
}) async {
  if (Platform.isLinux || Platform.isWindows) {
    return openLoopbackGoogleBrowser(
      authorize: authorize,
      state: state,
      cancelled: cancelled,
    );
  }
  final callback = Uri.parse(mobileGoogleRedirect);
  final responses = AppLinks().uriLinkStream.where(
    (uri) => matchesGoogleRedirect(callback, uri, state),
  );
  final reply = Completer<Uri?>();
  final subscription = responses.listen(
    (uri) {
      if (!reply.isCompleted) reply.complete(uri);
    },
    onError: (Object _) {
      if (!reply.isCompleted) reply.complete(null);
    },
  );
  try {
    await _launchBrowser(authorize(callback));
    return await _awaitResponse(reply.future, cancelled);
  } finally {
    await subscription.cancel();
  }
}

Future<Uri> openLoopbackGoogleBrowser({
  required Uri Function(Uri) authorize,
  required String state,
  required Future<void> cancelled,
  Future<void> Function(Uri) launch = _launchBrowser,
}) async {
  final HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  } on SocketException {
    throw googleBrowserUnavailable;
  }
  final callback = Uri(
    scheme: 'http',
    host: server.address.address,
    port: server.port,
    path: '/oauth/google',
  );
  final reply = Completer<Uri?>();
  final subscription = server.listen(
    (request) async {
      final target = callback.resolveUri(request.uri);
      final valid =
          request.method == 'GET' &&
          request.headers.value(HttpHeaders.hostHeader) == callback.authority &&
          matchesGoogleRedirect(callback, target, state);
      final response = request.response;
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      response.headers.set('referrer-policy', 'no-referrer');
      response.headers.set(
        'content-security-policy',
        "default-src 'none'; frame-ancestors 'none'",
      );
      response.statusCode = valid ? HttpStatus.ok : HttpStatus.notFound;
      if (valid) {
        response.headers.contentType = ContentType.html;
        response.write(
          '<!doctype html><html lang="id"><meta charset="utf-8">'
          '<title>Kantin Cerdas</title><p>Kembali ke aplikasi Kantin Cerdas.</p></html>',
        );
      }
      try {
        await response.close();
      } on HttpException {
        // Closing the browser tab must not keep the app waiting.
      }
      if (valid && !reply.isCompleted) reply.complete(target);
    },
    onError: (Object _) {
      if (!reply.isCompleted) reply.complete(null);
    },
  );

  try {
    await launch(authorize(callback));
    return await _awaitResponse(reply.future, cancelled);
  } finally {
    await subscription.cancel();
    await server.close(force: true);
  }
}

Future<void> _launchBrowser(Uri url) async {
  try {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw googleBrowserUnavailable;
    }
  } on PlatformException {
    throw googleBrowserUnavailable;
  }
}

Future<Uri> _awaitResponse(
  Future<Uri?> response,
  Future<void> cancelled,
) async {
  final link = await Future.any<Uri?>([
    response,
    cancelled.then((_) => null),
  ]).timeout(googleRedirectTimeout);
  if (link == null) throw googleCancelled;
  return link;
}

import 'dart:async';
import 'dart:js_interop';

import 'package:kantin_cerdas/features/auth/data/oauth/google_oauth_protocol.dart';
import 'package:web/web.dart' as web;

Future<Uri> openGoogleBrowser({
  required Uri Function(Uri) authorize,
  required String state,
  required Future<void> cancelled,
}) async {
  final root = Uri.parse(web.document.baseURI);
  final callback = root.resolve('auth-return.html');
  if (callback.origin != web.window.location.origin ||
      (callback.scheme != 'https' &&
          !(callback.scheme == 'http' &&
              {'localhost', '127.0.0.1'}.contains(callback.host)))) {
    throw googleBrowserUnavailable;
  }

  // The channel is same-origin and scoped to this randomly generated state.
  // It remains usable even if an OAuth page severs the popup's opener.
  final channel = web.BroadcastChannel('kc-google-$state');
  final result = Completer<Uri?>();
  final receive = ((web.MessageEvent event) {
    final payload = event.data;
    if (payload == null || !payload.typeofEquals('string')) return;
    final uri = Uri.tryParse((payload as JSString).toDart);
    if (uri != null &&
        matchesGoogleRedirect(callback, uri, state) &&
        !result.isCompleted) {
      result.complete(uri);
    }
  }).toJS;
  channel.addEventListener('message', receive);

  web.Window? popup;
  try {
    popup = web.window.open(
      'about:blank',
      '_blank',
      'popup,width=520,height=720',
    );
    if (popup == null) throw googleBrowserUnavailable;
    popup.opener = null;
    popup.location.replace(authorize(callback).toString());
    final link = await Future.any<Uri?>([
      result.future,
      cancelled.then((_) => null),
    ]).timeout(googleRedirectTimeout);
    if (link == null) throw googleCancelled;
    return link;
  } finally {
    channel.removeEventListener('message', receive);
    channel.close();
    popup?.close();
  }
}

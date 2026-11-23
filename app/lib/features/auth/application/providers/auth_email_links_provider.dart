import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_email_link.dart';

final authEmailLinksProvider = StreamProvider<AuthEmailLink>((ref) async* {
  const host = String.fromEnvironment('AUTH_EMAIL_LINK_HOST');

  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  await for (final uri in AppLinks().uriLinkStream) {
    final link = AuthEmailLink.parse(uri, allowedHost: host);
    if (link != null) yield link;
  }
}, retry: (_, _) => null);

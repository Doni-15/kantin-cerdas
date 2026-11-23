import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_email_link.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/auth_email_link_view.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/splash_screen.dart';

/// Preserves the underlying screen state via [Offstage] and [TickerMode] while
/// displaying an incoming email deep-link screen above it.
Widget buildAuthEmailLinkOverlay({
  required Widget screen,
  required AuthEmailLink? activeLink,
  required AsyncValue<AuthSession?> session,
  required void Function(String? notice, bool requestNew) onCloseLink,
}) {
  if (screen is SplashScreen && activeLink == null) {
    return screen;
  }

  return Stack(
    fit: StackFit.expand,
    children: [
      if (screen is! SplashScreen)
        Offstage(
          offstage: activeLink != null,
          child: TickerMode(enabled: activeLink == null, child: screen),
        ),

      if (activeLink != null)
        AuthEmailLinkScreen(
          key: ObjectKey(activeLink),
          link: activeLink,
          session: session,
          onClose: onCloseLink,
        ),
    ],
  );
}

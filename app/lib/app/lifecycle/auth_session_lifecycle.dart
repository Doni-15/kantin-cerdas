import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';

AppLifecycleListener createAuthSessionLifecycleListener(WidgetRef ref) {
  return AppLifecycleListener(
    onResume: () {
      if (ref.read(authControllerProvider).asData?.value != null) {
        unawaited(
          ref.read(authControllerProvider.notifier).revalidateOnResume(),
        );
      }
    },
  );
}

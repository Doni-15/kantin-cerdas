import 'package:flutter/widgets.dart';

import 'package:kantin_cerdas/app/kantin_cerdas_app.dart';

import 'demo_role.dart';
import 'demo_scope.dart';
import 'demo_session.dart';

Widget createDemoApp(DemoRole role) {
  final session = switch (role) {
    DemoRole.student => const DemoSession.student(),
    DemoRole.manager => const DemoSession.manager(),
  };

  return DemoScope(session: session, child: const KantinCerdasApp());
}

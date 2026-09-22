import 'package:flutter/widgets.dart';

import 'demo_session.dart';

class DemoScope extends InheritedWidget {
  const DemoScope({required this.session, required super.child, super.key});

  final DemoSession session;

  static DemoSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DemoScope>();

    assert(scope != null, 'DemoScope tidak ditemukan di widget tree.');

    return scope!.session;
  }

  @override
  bool updateShouldNotify(DemoScope oldWidget) {
    return session != oldWidget.session;
  }
}

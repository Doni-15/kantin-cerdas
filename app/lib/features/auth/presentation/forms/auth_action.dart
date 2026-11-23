import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';

mixin AuthAction<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  String? problem;

  Future<void> runAction(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      if (mounted) setState(() => problem = authMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

String authMessage(Object? error) => presentAuthError(error);

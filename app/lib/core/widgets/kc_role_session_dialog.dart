import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/auth_state_provider.dart';
import 'package:kantin_cerdas/core/session/user_role.dart';

/// Identitas sesi, termasuk logout lalu login lagi ke akun yang sama.
class KcRoleSession {
  KcRoleSession(WidgetRef ref, {required this.role})
    : actorId = ref.read(authStateProvider).asData?.value?.id,
      notifier = ref.read(authStateProvider.notifier),
      generation = ref.read(authStateProvider.notifier).sessionGeneration;

  final UserRole role;
  final String? actorId;
  final AuthStateNotifier notifier;
  final int generation;

  // Pemanggil wajib memeriksa mounted sebelum memakai WidgetRef.
  bool isCurrent(WidgetRef ref) {
    final auth = ref.read(authStateProvider);
    final user = auth.asData?.value;
    final current = ref.read(authStateProvider.notifier);
    return !auth.isLoading &&
        !auth.hasError &&
        user != null &&
        user.isActive &&
        user.role.allows(role) &&
        user.id == actorId &&
        identical(current, notifier) &&
        current.sessionGeneration == generation;
  }
}

/// Setiap dialog mempunyai route sendiri, sehingga pergantian sesi menutup
/// dialog yang tepat tanpa mem-pop halaman atau dialog milik sesi baru.
Future<T?> showKcRoleDialog<T>({
  required BuildContext context,
  required WidgetRef ref,
  required UserRole role,
  required WidgetBuilder builder,
}) async {
  final session = KcRoleSession(ref, role: role);
  if (!session.isCurrent(ref)) {
    return null;
  }
  final result = await showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _KcRoleSessionDialog(session: session, builder: builder),
  );
  if (!context.mounted || !session.isCurrent(ref)) {
    return null;
  }
  return result;
}

class _KcRoleSessionDialog extends ConsumerStatefulWidget {
  const _KcRoleSessionDialog({required this.session, required this.builder});
  final KcRoleSession session;
  final WidgetBuilder builder;

  @override
  ConsumerState<_KcRoleSessionDialog> createState() =>
      _KcRoleSessionDialogState();
}

class _KcRoleSessionDialogState extends ConsumerState<_KcRoleSessionDialog> {
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    ref.watch(authStateProvider.notifier);
    if (!widget.session.isCurrent(ref)) {
      if (!_closing) {
        _closing = true;
        final route = ModalRoute.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || route == null || !route.isActive) {
            return;
          }
          route.navigator?.removeRoute(route);
        });
      }
      return const SizedBox.shrink();
    }
    return widget.builder(context);
  }
}

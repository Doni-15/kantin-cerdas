import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_mutation_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_session_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_user_access_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/users/admin_user_access_dialog.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

class AdminUserAccessActions extends ConsumerStatefulWidget {
  const AdminUserAccessActions({super.key, required this.record});
  final AdminUserRecord record;
  @override
  ConsumerState<AdminUserAccessActions> createState() =>
      _AdminUserAccessActionsState();
}

class _AdminUserAccessActionsState
    extends ConsumerState<AdminUserAccessActions> {
  bool _confirming = false;
  String _reason = '';
  Future<void> _change() async {
    if (_confirming || ref.read(adminMutationProvider).blocked) {
      return;
    }
    final record = widget.record;
    final session = ref.read(authStateProvider.notifier);
    final generation = session.sessionGeneration;
    final revision = ref.read(adminMutationProvider).revision;
    setState(() => _confirming = true);
    try {
      final reason = await showAdminDialog<String>(
        context: context,
        ref: ref,
        builder: (context) => AdminUserAccessDialog(
          name: record.user.name,
          username: record.user.username,
          activate: !record.user.isActive,
          initialReason: _reason,
        ),
      );
      if (!mounted ||
          reason == null ||
          !identical(session, ref.read(authStateProvider.notifier)) ||
          generation != session.sessionGeneration ||
          revision != ref.read(adminMutationProvider).revision ||
          ref.read(adminMutationProvider).blocked) {
        return;
      }
      _reason = reason;
      await ref
          .read(adminMutationControllerProvider.notifier)
          .changeAccess(
            AdminUserAccessChange(
              userId: record.user.id,
              expectedVersion: record.version,
              isActive: !record.user.isActive,
              reason: reason,
            ),
          );
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final actor = auth.asData?.value;
    final attempt = ref.watch(
      adminUserAccessControllerProvider,
    )[widget.record.user.id];
    if (auth.isLoading ||
        auth.hasError ||
        actor == null ||
        !actor.isActive ||
        actor.role != UserRole.admin) {
      return const Text('Sesi admin aktif diperlukan untuk mengubah akses.');
    }
    if (actor.id == widget.record.user.id) {
      return const Text(
        'Akses akun sendiri tidak dapat diubah melalui halaman ini.',
      );
    }
    if (!widget.record.canManage(actor.id)) {
      return const Text(
        'Akses akun admin tidak dapat diubah melalui halaman ini.',
      );
    }
    final shared = ref.watch(adminMutationProvider);
    if (!shared.configured) {
      return const Text('Layanan perubahan admin belum tersedia saat ini.');
    }
    if (shared.journalLoading) {
      return const Text('Sedang memeriksa penanda perubahan tersimpan.');
    }
    final blocked =
        _confirming || shared.blocked || (attempt?.blocked ?? false);
    return OutlinedButton.icon(
      onPressed: blocked ? null : _change,
      icon: Icon(
        widget.record.user.isActive ? Icons.block : Icons.check_circle_outline,
      ),
      label: Text(
        widget.record.user.isActive ? 'Nonaktifkan akun' : 'Aktifkan akun',
      ),
    );
  }
}

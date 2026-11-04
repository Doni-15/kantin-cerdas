import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

class OwnerDialogSession extends KcRoleSession {
  OwnerDialogSession(super.ref) : super(role: UserRole.owner);
  String? get ownerId => actorId;
}

Future<T?> showOwnerDialog<T>({
  required BuildContext context,
  required WidgetRef ref,
  required WidgetBuilder builder,
}) => showKcRoleDialog<T>(
  context: context,
  ref: ref,
  role: UserRole.owner,
  builder: builder,
);

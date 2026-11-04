import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

Future<T?> showAdminDialog<T>({
  required BuildContext context,
  required WidgetRef ref,
  required WidgetBuilder builder,
}) => showKcRoleDialog<T>(
  context: context,
  ref: ref,
  role: UserRole.admin,
  builder: builder,
);

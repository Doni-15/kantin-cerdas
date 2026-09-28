import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/shell/customer_shell.dart';
import 'package:kantin_cerdas/features/shell/owner_shell.dart';
import 'package:kantin_cerdas/features/shell/admin_shell.dart';

class AppEntryPage extends ConsumerStatefulWidget {
  const AppEntryPage({super.key});

  @override
  ConsumerState<AppEntryPage> createState() => _AppEntryPageState();
}

class _AppEntryPageState extends ConsumerState<AppEntryPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider);

      if (user != null) {
        KcSnackBar.success(
          context,
          'Login berhasil. Selamat datang, ${user.name}!',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

    return switch (user!.role) {
      UserRole.customer => CustomerShell(user: user),
      UserRole.owner => OwnerShell(user: user),
      UserRole.admin => AdminShell(user: user),
    };
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/shell/admin_shell.dart';
import 'package:kantin_cerdas/features/shell/customer_shell.dart';
import 'package:kantin_cerdas/features/shell/owner_shell.dart';

/// Pintu masuk setelah login / sesi dipulihkan: memilih shell sesuai role.
///
/// Pesan sambutan login ada di LoginForm, bukan di sini, agar tidak muncul
/// setiap kali sesi dipulihkan saat aplikasi dibuka.
class AppEntryPage extends ConsumerWidget {
  const AppEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    // Setelah logout, state auth menjadi null sesaat sebelum halaman login
    // tampil (transisi masih berjalan). Jangan crash pada rebuild itu.
    if (user == null) {
      return const SizedBox.shrink();
    }

    return switch (user.role) {
      UserRole.customer => CustomerShell(user: user),
      UserRole.owner => OwnerShell(user: user),
      UserRole.admin => AdminShell(user: user),
    };
  }
}

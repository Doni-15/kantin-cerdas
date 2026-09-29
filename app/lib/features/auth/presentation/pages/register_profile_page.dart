import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/core/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/register_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/register_draft_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';

class RegisterProfilePage extends ConsumerStatefulWidget {
  const RegisterProfilePage({super.key});

  @override
  ConsumerState<RegisterProfilePage> createState() =>
      _RegisterProfilePageState();
}

class _RegisterProfilePageState extends ConsumerState<RegisterProfilePage> {
  final _usernameController = TextEditingController();

  String? _usernameError;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    FocusScope.of(context).unfocus();

    // Cegah double-submit (mis. Enter di keyboard saat request masih berjalan).
    if (ref.read(registerControllerProvider).isLoading) {
      return;
    }

    final draft = ref.read(registerDraftProvider);

    if (draft == null) {
      // Data langkah 1 tidak ada (state ter-reset): kembali ke langkah 1.
      Navigator.of(context).pop();
      return;
    }

    final username = _usernameController.text.trim();

    setState(() {
      _usernameError = AuthValidator.username(username);
    });

    if (_usernameError != null) {
      return;
    }

    ref.read(registerControllerProvider.notifier).register(
          name: draft.name,
          username: username,
          email: draft.email,
          password: draft.password,
        );
  }

  void _handlePickPhoto() {
    KcSnackBar.info(
      context,
      'Fitur pilih foto belum tersedia.',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(
      registerControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (user) {
            if (user == null) {
              return;
            }

            ref.read(registerDraftProvider.notifier).clear();

            KcSnackBar.success(
              context,
              'Registrasi berhasil.',
            );

            context.go(Routes.login);
          },
          error: (error, stackTrace) {
            // Error milik field username: tampilkan di bawah field-nya.
            if (error is UsernameTakenFailure) {
              setState(() {
                _usernameError = authErrorMessage(error);
              });
              return;
            }

            if (error is ValidationFailure &&
                error.fieldErrors.containsKey('username')) {
              setState(() {
                _usernameError = error.fieldErrors['username'];
              });
              return;
            }

            KcSnackBar.error(
              context,
              authErrorMessage(error),
            );

            // Email diisi di langkah 1: kembalikan user ke sana untuk memperbaikinya.
            if (error is EmailTakenFailure) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );

    final registerState = ref.watch(
      registerControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Profil'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildAvatar(),
            const SizedBox(height: 32),
            _buildUsernameField(),
            const SizedBox(height: 32),
            KcButton(
              label: 'SELESAI REGISTRASI',
              onPressed: _handleRegister,
              isLoading: registerState.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lengkapi profil',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tambahkan username dan foto profil untuk menyelesaikan registrasi.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _handlePickPhoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Tambah Foto Profil'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return KcTextField(
      label: 'Username',
      hint: 'Masukkan username',
      controller: _usernameController,
      prefixIcon: Icons.alternate_email,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleRegister(),
      errorText: _usernameError,
      onChanged: (_) {
        if (_usernameError != null) {
          setState(() {
            _usernameError = null;
          });
        }
      },
    );
  }
}

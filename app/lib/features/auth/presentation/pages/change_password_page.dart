import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/change_password_controller.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';

/// Halaman Ubah Password. Dipakai semua role lewat Keamanan Akun.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    // Cegah double-submit (mis. Enter di keyboard saat request masih berjalan).
    if (ref.read(changePasswordControllerProvider).isLoading) {
      return;
    }

    final current = _currentController.text;
    final next = _newController.text;
    final confirmation = _confirmController.text;

    setState(() {
      _currentError = AuthValidator.currentPassword(current);
      _newError = AuthValidator.newPassword(current, next);
      _confirmError = AuthValidator.confirmPassword(next, confirmation);
    });

    if (_currentError != null || _newError != null || _confirmError != null) {
      return;
    }

    ref
        .read(changePasswordControllerProvider.notifier)
        .changePassword(currentPassword: current, newPassword: next);
  }

  void _handleError(Object error) {
    // Password saat ini salah: tampilkan di bawah field-nya.
    if (error is InvalidCurrentPasswordFailure) {
      setState(() {
        _currentError = authErrorMessage(error);
      });
      return;
    }

    // Error milik field (422 dari server): tampilkan di bawah field-nya.
    if (error is ValidationFailure) {
      final errors = error.fieldErrors;

      if (errors.containsKey('current_password') ||
          errors.containsKey('new_password')) {
        setState(() {
          _currentError = errors['current_password'] ?? _currentError;
          _newError = errors['new_password'] ?? _newError;
        });
        return;
      }
    }

    KcSnackBar.error(context, authErrorMessage(error));
  }

  Widget _visibilityToggle({
    required bool obscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(changePasswordControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (success) {
          if (!success) {
            return;
          }

          KcSnackBar.success(context, 'Password berhasil diubah.');
          context.pop();
        },
        error: (error, stackTrace) => _handleError(error),
      );
    });

    final isLoading = ref.watch(changePasswordControllerProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Password'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          Text(
            'Password baru minimal ${AuthValidator.minPasswordLength} karakter '
            'dan harus berbeda dari password saat ini.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 32),
          KcTextField(
            label: 'Password Saat Ini',
            hint: 'Masukkan password saat ini',
            controller: _currentController,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureCurrent,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            errorText: _currentError,
            onChanged: (_) {
              if (_currentError != null) {
                setState(() {
                  _currentError = null;
                });
              }
            },
            suffixIcon: _visibilityToggle(
              obscured: _obscureCurrent,
              onPressed: () => setState(() {
                _obscureCurrent = !_obscureCurrent;
              }),
            ),
          ),
          const SizedBox(height: 16),
          KcTextField(
            label: 'Password Baru',
            hint: 'Masukkan password baru',
            controller: _newController,
            prefixIcon: Icons.lock_reset_outlined,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            errorText: _newError,
            onChanged: (_) {
              if (_newError != null) {
                setState(() {
                  _newError = null;
                });
              }
            },
            suffixIcon: _visibilityToggle(
              obscured: _obscureNew,
              onPressed: () => setState(() {
                _obscureNew = !_obscureNew;
              }),
            ),
          ),
          const SizedBox(height: 16),
          KcTextField(
            label: 'Konfirmasi Password Baru',
            hint: 'Ulangi password baru',
            controller: _confirmController,
            prefixIcon: Icons.lock_reset_outlined,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            enabled: !isLoading,
            errorText: _confirmError,
            onChanged: (_) {
              if (_confirmError != null) {
                setState(() {
                  _confirmError = null;
                });
              }
            },
            suffixIcon: _visibilityToggle(
              obscured: _obscureConfirm,
              onPressed: () => setState(() {
                _obscureConfirm = !_obscureConfirm;
              }),
            ),
          ),
          const SizedBox(height: 32),
          KcButton(
            label: 'SIMPAN PASSWORD',
            onPressed: _submit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

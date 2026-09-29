import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/core/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_brand.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_logo.dart';
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/login_controller.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/utils/auth_error_message.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();

    // Cegah double-submit (mis. Enter di keyboard saat request masih berjalan).
    if (ref.read(loginControllerProvider).isLoading) {
      return;
    }

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _identifierError = AuthValidator.identifier(identifier);
      _passwordError = AuthValidator.loginPassword(password);
    });

    if (_identifierError != null || _passwordError != null) {
      return;
    }

    ref.read(loginControllerProvider.notifier).login(
      identifier: identifier,
      password: password,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(
      loginControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (user) {
            if (user == null) {
              return;
            }

            // Auth state sudah di-set oleh LoginController dan router akan
            // mengarahkan ke /app. Snackbar ditampilkan di sini (bukan di
            // halaman utama) agar tidak muncul saat sesi dipulihkan.
            KcSnackBar.success(
              context,
              'Login berhasil. Selamat datang, ${user.name}!',
            );

            context.go(Routes.app);
          },
          error: (error, stackTrace) {
            KcSnackBar.error(
              context,
              authErrorMessage(error),
            );
          },
        );
      },
    );

    final loginState = ref.watch(
      loginControllerProvider,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),

        const SizedBox(height: 40),

        _buildIdentifierField(),

        const SizedBox(height: 16),

        _buildPasswordField(),

        _buildForgotPassword(),

        const SizedBox(height: 16),

        _buildLoginButton(
          isLoading: loginState.isLoading,
        ),

        const SizedBox(height: 32),

        _buildDivider(),

        const SizedBox(height: 32),

        _buildGoogleButton(),

        const SizedBox(height: 48),

        _buildRegisterPrompt(),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Column(
      children: [
        const KcBrand(
          logoSize: 68,
        ),
        const SizedBox(height: 32),
        Text(
          'Selamat datang kembali!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Masuk untuk melanjutkan ke KantinCerdas',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildIdentifierField() {
    return KcTextField(
      label: 'Username atau Email',
      hint: 'Masukkan username atau email',
      controller: _identifierController,
      prefixIcon: Icons.person_outline,
      textInputAction: TextInputAction.next,
      errorText: _identifierError,
      onChanged: (_) {
        if (_identifierError != null) {
          setState(() {
            _identifierError = null;
          });
        }
      },
    );
  }

  Widget _buildPasswordField() {
    return KcTextField(
      label: 'Password',
      hint: 'Masukkan password',
      controller: _passwordController,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleLogin(),
      errorText: _passwordError,
      onChanged: (_) {
        if (_passwordError != null) {
          setState(() {
            _passwordError = null;
          });
        }
      },
      suffixIcon: IconButton(
        onPressed: _togglePasswordVisibility,
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          KcSnackBar.info(
            context,
            'Fitur lupa password belum tersedia.',
          );
        },
        child: const Text('Lupa password?'),
      ),
    );
  }

  Widget _buildLoginButton({
    required bool isLoading,
  }) {
    return KcButton(
      label: 'MASUK',
      onPressed: _handleLogin,
      isLoading: isLoading,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(
          child: Divider(),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return KcButton(
      label: 'Masuk dengan Google',
      variant: KcButtonVariant.outlined,
      leading: const KcLogo(
        assetPath: 'assets/images/logos/google_logo.png',
        size: 20,
      ),
      onPressed: () {
        KcSnackBar.info(
          context,
          'Login dengan Google belum tersedia.',
        );
      },
    );
  }

  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            context.push(Routes.register);
          },
          child: const Text('Daftar'),
        ),
      ],
    );
  }
}
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
import 'package:kantin_cerdas/features/auth/presentation/controllers/register_controller.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _handleRegister() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty
    ) {
      KcSnackBar.error(
        context,
        'Silakan lengkapi semua data.',
      );
      return;
    }

    if (password != confirmPassword) {
      KcSnackBar.error(
        context,
        'Konfirmasi password tidak sesuai.',
      );
      return;
    }

    ref.read(registerControllerProvider.notifier).register(
          name: name,
          username: username,
          email: email,
          password: password,
        );
  }

  void _handleGoogleRegister() {
    KcSnackBar.info(
      context,
      'Login dengan Google belum tersedia.',
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

            KcSnackBar.success(
              context,
              'Registrasi berhasil.',
            );

            context.go(Routes.login);
          },
          error: (error, stackTrace) {
            KcSnackBar.error(
              context,
              error.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
            );
          },
        );
      },
    );

    final registerState = ref.watch(
      registerControllerProvider,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),

        // Diperbesar dari 24 ke 40 untuk memisahkan area teks sambutan dan form (konsisten dengan Login)
        const SizedBox(height: 40),

        _buildNameField(),

        const SizedBox(height: 16),

        _buildUsernameField(),

        const SizedBox(height: 16),

        _buildEmailField(),

        const SizedBox(height: 16),

        _buildPasswordField(),

        const SizedBox(height: 16),

        _buildConfirmPasswordField(),

        // Diperbesar dari 24 ke 32 agar ada jarak lebih jelas antara input terakhir dan tombol aksi
        const SizedBox(height: 32),

        _buildRegisterButton(
          isLoading: registerState.isLoading,
        ),

        // Diperbesar dari 24 ke 32 agar proporsional dengan tombol (konsisten dengan Login)
        const SizedBox(height: 32),

        _buildDivider(),

        // Diperbesar dari 24 ke 32 (konsisten dengan Login)
        const SizedBox(height: 32),

        _buildGoogleButton(),

        // Diperbesar dari 8 ke 48 agar bagian 'Sudah punya akun' terdorong sedikit ke bawah menjadi footer (konsisten dengan Login)
        const SizedBox(height: 48),

        _buildLoginPrompt(),
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
          'Buat akun baru',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),

        const SizedBox(height: 8),

        Text(
          'Daftar untuk mulai menggunakan KantinCerdas',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return KcTextField(
      label: 'Nama',
      hint: 'Nama lengkap',
      controller: _nameController,
      prefixIcon: Icons.person_outline,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildUsernameField() {
    return KcTextField(
      label: 'Username',
      hint: 'Masukkan username',
      controller: _usernameController,
      prefixIcon: Icons.person_outline,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildEmailField() {
    return KcTextField(
      label: 'Email',
      hint: 'nama@email.com',
      controller: _emailController,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return KcTextField(
      label: 'Password',
      hint: 'Masukkan password',
      controller: _passwordController,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
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

  Widget _buildConfirmPasswordField() {
    return KcTextField(
      label: 'Konfirmasi Password',
      hint: 'Masukkan ulang password',
      controller: _confirmPasswordController,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleRegister(),
      suffixIcon: IconButton(
        onPressed: _toggleConfirmPasswordVisibility,
        icon: Icon(
          _obscureConfirmPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    );
  }

  Widget _buildRegisterButton({
    required bool isLoading,
  }) {
    return KcButton(
      label: 'DAFTAR',
      onPressed: _handleRegister,
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
      label: 'Daftar dengan Google',
      variant: KcButtonVariant.outlined,
      leading: const KcLogo(
        assetPath: 'assets/images/logos/google_logo.png',
        size: 20,
      ),
      onPressed: _handleGoogleRegister,
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            context.go(Routes.login);
          },
          child: const Text('Masuk'),
        ),
      ],
    );
  }
}
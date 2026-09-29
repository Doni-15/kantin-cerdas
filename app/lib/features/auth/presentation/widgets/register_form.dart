import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/core/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_brand.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_logo.dart';
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/register_profile_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/register_draft_provider.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
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
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _nameError = AuthValidator.name(name);
      _emailError = AuthValidator.email(email);
      _passwordError = AuthValidator.password(password);
      _confirmPasswordError = AuthValidator.confirmPassword(
        password,
        confirmPassword,
      );
    });

    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    // Data langkah 1 disimpan di provider, bukan dilempar lewat constructor.
    ref.read(registerDraftProvider.notifier).setDraft(
          RegisterDraft(
            name: name,
            email: email,
            password: password,
          ),
        );

    // TODO: pindahkan ke route GoRouter (mis. Routes.registerProfile) agar
    // konsisten dengan navigasi lain dan mendukung back stack / deep link.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterProfilePage(),
      ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),

        const SizedBox(height: 40),

        _buildNameField(),

        const SizedBox(height: 16),

        _buildEmailField(),

        const SizedBox(height: 16),

        _buildPasswordField(),

        const SizedBox(height: 16),

        _buildConfirmPasswordField(),

        const SizedBox(height: 32),

        _buildRegisterButton(),

        const SizedBox(height: 32),

        _buildDivider(),

        const SizedBox(height: 32),

        _buildGoogleButton(),

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
      errorText: _nameError,
      onChanged: (_) {
        if (_nameError != null) {
          setState(() {
            _nameError = null;
          });
        }
      },
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
      errorText: _emailError,
      onChanged: (_) {
        if (_emailError != null) {
          setState(() {
            _emailError = null;
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
      textInputAction: TextInputAction.next,
      errorText: _passwordError,
      onChanged: (_) {
        setState(() {
          _passwordError = null;

          if (_confirmPasswordError ==
              'Konfirmasi password tidak sesuai') {
            _confirmPasswordError = null;
          }
        });
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

  Widget _buildConfirmPasswordField() {
    return KcTextField(
      label: 'Konfirmasi Password',
      hint: 'Masukkan ulang password',
      controller: _confirmPasswordController,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleRegister(),
      errorText: _confirmPasswordError,
      onChanged: (_) {
        if (_confirmPasswordError != null) {
          setState(() {
            _confirmPasswordError = null;
          });
        }
      },
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

  Widget _buildRegisterButton() {
    return KcButton(
      label: 'LANJUT',
      onPressed: _handleRegister,
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
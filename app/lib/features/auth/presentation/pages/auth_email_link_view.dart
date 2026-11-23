import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_email_link_service.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_email_link.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';
import 'package:kantin_cerdas/features/auth/presentation/forms/reset_password_fields.dart';

class AuthEmailLinkScreen extends ConsumerStatefulWidget {
  const AuthEmailLinkScreen({
    super.key,
    required this.link,
    required this.session,
    required this.onClose,
  });

  final AuthEmailLink link;
  final AsyncValue<AuthSession?> session;
  final void Function(String? notice, bool requestNew) onClose;

  @override
  ConsumerState<AuthEmailLinkScreen> createState() => _EmailLinkScreenState();
}

class _EmailLinkScreenState extends ConsumerState<AuthEmailLinkScreen>
    with AuthAction<AuthEmailLinkScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Future<void>? _recoveryCheck;
  var _obscured = true;
  var _rejected = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _checkRecoveryLink();
  }

  void _checkRecoveryLink() {
    _recoveryCheck = ref
        .read(authEmailLinkServiceProvider)
        .checkRecoveryLinkIfNeeded(widget.link);
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit(String hash) async {
    if (!_form.currentState!.validate()) return;
    final linkService = ref.read(authEmailLinkServiceProvider);
    await runAction(() async {
      try {
        final message = await linkService.submitEmailLink(
          widget.link,
          tokenHash: hash,
          newPassword: _password.text,
        );
        if (!mounted) return;
        if (message == null) {
          widget.onClose(null, false);
        } else {
          setState(() => _result = message);
        }
      } on AuthException catch (error) {
        if (error.code == 'INVALID_CODE' && mounted) {
          setState(() => _rejected = true);
        } else if (widget.link.action == AuthEmailAction.recovery &&
            mounted &&
            (error.code == 'WEAK_PASSWORD' || error.code == 'SAME_PASSWORD')) {
          setState(() {
            _rejected = true;
            _result = authMessage(error);
          });
        }
        rethrow;
      }
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _recoveryCheck,
    builder: (context, check) {
      final action = widget.link.action;
      final hash = widget.link.tokenHash;
      final callback = widget.link.isCallback;
      final reset = action == AuthEmailAction.recovery;
      final active = widget.session.asData?.value;
      final cannotSignIn =
          action == AuthEmailAction.signup &&
          (active != null ||
              widget.session.isLoading ||
              widget.session.hasError);
      final checking = check.connectionState == ConnectionState.waiting;
      final checkError = checking ? null : check.error;
      final invalid =
          widget.link.isInvalid ||
          (!callback && hash == null) ||
          _rejected ||
          checkError is AuthException && checkError.code == 'INVALID_CODE';
      final ready = !invalid && !checking && checkError == null;
      return AuthLayout(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: BackButton(
                  onPressed: busy ? null : () => widget.onClose(null, false),
                ),
              ),
              AuthHeading(
                centered: true,
                title: switch (action) {
                  AuthEmailAction.signup => 'Verifikasi Email',
                  AuthEmailAction.recovery => 'Buat password baru',
                  AuthEmailAction.emailChange => 'Konfirmasi perubahan email',
                },
                subtitle:
                    _result ??
                    (invalid
                        ? 'Tautan tidak valid, sudah digunakan, atau kedaluwarsa.'
                        : (reset
                              ? 'Gunakan password baru untuk mengamankan akunmu.'
                              : (callback
                                    ? 'Masuk ke akunmu untuk memeriksa status verifikasi email.'
                                    : 'Lanjutkan jika kamu meminta tautan ini.'))),
              ),
              if (cannotSignIn)
                const AuthNotice(
                  'Tutup layar ini. Verifikasi pendaftaran tersedia dari layar masuk.',
                ),
              if (problem != null && !invalid) AuthNotice(problem!),
              if (checking)
                const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Memeriksa tautan',
                  ),
                ),
              if (checkError != null && !invalid) ...[
                AuthNotice(authMessage(checkError)),
                OutlinedButton(
                  onPressed: () => setState(_checkRecoveryLink),
                  child: const Text('Coba lagi'),
                ),
              ],

              if (reset && ready && _result == null)
                ...resetPasswordFields(
                  password: _password,
                  confirmation: _confirmation,
                  busy: busy,
                  obscured: _obscured,
                  toggleObscured: () => setState(() => _obscured = !_obscured),
                ),
              if (ready && !cannotSignIn && _result == null && hash != null)
                FilledButton(
                  onPressed: busy ? null : () => _submit(hash),
                  child: Text(
                    busy
                        ? 'Memproses…'
                        : (reset ? 'Simpan password baru' : 'Konfirmasi'),
                  ),
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        await runAction(
                          () => ref
                              .read(authEmailLinkServiceProvider)
                              .reloadAccountAfterEmailChangeIfNeeded(
                                link: widget.link,
                                resultMessage: _result,
                                activeSession: active,
                              ),
                        );
                        if (mounted) {
                          widget.onClose(
                            invalid ? null : _result,
                            reset && invalid && active == null,
                          );
                        }
                      },
                child: Text(
                  reset && invalid && active == null
                      ? 'Minta tautan baru'
                      : (active == null ? 'Kembali ke Masuk' : 'Tutup'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

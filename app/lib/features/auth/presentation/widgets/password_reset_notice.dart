import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/presentation/controllers/password_reset_state.dart';

class PasswordResetNotice extends StatelessWidget {
  const PasswordResetNotice({super.key, required this.state});

  final PasswordResetState state;

  @override
  Widget build(BuildContext context) {
    if (state.isSubmitting) {
      return Semantics(
        liveRegion: true,
        child: const Text('Meminta petunjuk pemulihan. Tunggu sebentar…'),
      );
    }
    if (state.isAcknowledged) {
      return const KcStatusPanel(
        title: 'Permintaan diterima',
        message:
            'Jika email terhubung ke akun yang dapat dipulihkan, petunjuk akan '
            'dikirim ke alamat tersebut. Periksa kotak masuk dan folder spam.',
        icon: Icons.mark_email_read_outlined,
      );
    }
    final failure = state.failure;
    if (failure == null) {
      return const SizedBox.shrink();
    }
    final (title, message) = switch (failure) {
      AuthNotConfiguredFailure() => (
        'Pemulihan belum tersedia',
        'Layanan pemulihan akun belum terhubung. Permintaan belum dikirim. '
            'Silakan kembali ke halaman masuk.',
      ),
      AuthRateLimitedFailure() => (
        'Permintaan dibatasi sementara',
        'Tunggu beberapa saat sebelum mencoba lagi. '
            'Jika sebelumnya sudah meminta pemulihan, periksa kotak masuk dan folder spam.',
      ),
      AuthValidationFailure() => (
        'Periksa email',
        'Masukkan alamat email yang valid, maksimal 254 karakter.',
      ),
      _ => (
        'Permintaan belum terkonfirmasi',
        'Petunjuk mungkin sudah dikirim. Periksa kotak masuk dan folder spam '
            'sebelum mengirim permintaan lagi.',
      ),
    };
    return KcStatusPanel(title: title, message: message);
  }
}

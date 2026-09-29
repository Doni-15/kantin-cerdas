import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';

/// Satu tempat untuk teks dan ikon setiap status pengajuan.
extension CanteenApplicationStatusPresentation on CanteenApplicationStatus {
  String get title {
    return switch (this) {
      CanteenApplicationStatus.submitted => 'Menunggu Review',
      CanteenApplicationStatus.underReview => 'Sedang Direview',
      CanteenApplicationStatus.approved => 'Pengajuan Disetujui',
      CanteenApplicationStatus.rejected => 'Pengajuan Ditolak',
    };
  }

  IconData get icon {
    return switch (this) {
      CanteenApplicationStatus.submitted => Icons.schedule_outlined,
      CanteenApplicationStatus.underReview => Icons.pending_actions_outlined,
      CanteenApplicationStatus.approved => Icons.check_circle_outline,
      CanteenApplicationStatus.rejected => Icons.cancel_outlined,
    };
  }

  /// Ringkasan singkat (kartu di Beranda).
  String get shortDescription {
    return switch (this) {
      CanteenApplicationStatus.submitted =>
        'Pengajuan kamu sudah dikirim dan sedang menunggu pemeriksaan admin.',
      CanteenApplicationStatus.underReview =>
        'Admin sedang memeriksa data pengajuan kantin kamu.',
      CanteenApplicationStatus.approved =>
        'Pengajuan kamu telah disetujui oleh admin.',
      CanteenApplicationStatus.rejected => 'Pengajuan kamu ditolak oleh admin.',
    };
  }

  /// Teks di bawah judul pada layar status.
  String get headerDescription {
    return switch (this) {
      CanteenApplicationStatus.submitted =>
        'Pengajuan kantin kamu sudah berhasil dikirim '
            'dan sedang menunggu pemeriksaan admin.',
      CanteenApplicationStatus.underReview =>
        'Admin sedang memeriksa data pengajuan kantin kamu.',
      CanteenApplicationStatus.approved =>
        'Selamat! Pengajuan kantin kamu telah disetujui oleh admin.',
      CanteenApplicationStatus.rejected =>
        'Pengajuan kantin kamu belum dapat disetujui oleh admin.',
    };
  }

  /// Teks di dalam kartu status. Untuk status ditolak, alasan dari admin diutamakan.
  String detailDescription({String? rejectionReason}) {
    return switch (this) {
      CanteenApplicationStatus.submitted =>
        'Pengajuan kamu sudah diterima. '
            'Silakan menunggu admin memeriksa pengajuan tersebut.',
      CanteenApplicationStatus.underReview =>
        'Admin sedang memeriksa data dan informasi '
            'kantin yang kamu ajukan.',
      CanteenApplicationStatus.approved =>
        'Pengajuan kamu telah disetujui. '
            'Kamu sekarang dapat melanjutkan pengelolaan kantin.',
      CanteenApplicationStatus.rejected => rejectionReason ??
          'Pengajuan kamu ditolak oleh admin. '
              'Silakan periksa kembali data pengajuan.',
    };
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const _contentMaxWidth = 640.0;

  // Metadata dan isi mengikuti naskah referensi proyek.
  static const _lastUpdated = '29 September 2026';

  static const _sections = <String, List<String>>{
    '1. Ketentuan umum': [
      'Pengguna wajib membaca dan memahami Syarat & Ketentuan '
          'sebelum menggunakan aplikasi.',
      'Dengan menggunakan aplikasi, pengguna dianggap telah memahami '
          'dan menyetujui ketentuan yang berlaku.',
    ],
    '2. Akun pengguna': [
      'Pengguna wajib memberikan informasi akun yang benar '
          'dan dapat dipertanggungjawabkan.',
      'Pengguna bertanggung jawab menjaga keamanan akun dan tidak '
          'membagikan informasi login kepada pihak lain.',
      'Setiap aktivitas yang dilakukan melalui akun menjadi '
          'tanggung jawab pemilik akun.',
    ],
    '3. Penggunaan aplikasi': [
      'Aplikasi digunakan untuk melakukan pemesanan makanan, melihat '
          'informasi kantin, dan menggunakan layanan lain yang tersedia.',
      'Pengguna wajib menggunakan aplikasi secara wajar dan tidak '
          'mengganggu operasional sistem.',
    ],
    '4. Pesanan dan transaksi': [
      'Pengguna bertanggung jawab memastikan informasi pesanan '
          'sudah benar sebelum melakukan konfirmasi.',
      'Status pesanan dapat berubah sesuai proses yang dilakukan '
          'oleh pihak terkait.',
      'Pembatalan, pembayaran, dan penyelesaian pesanan mengikuti '
          'ketentuan layanan yang berlaku.',
    ],
    '5. Pengajuan kantin': [
      'Pengguna dapat mengajukan pembukaan kantin melalui '
          'fitur yang tersedia.',
      'Informasi yang diberikan dalam pengajuan harus benar, lengkap, '
          'dan dapat dipertanggungjawabkan.',
      'Setiap pengajuan akan melalui proses pemeriksaan oleh admin.',
      'Persetujuan pengajuan tidak diberikan secara otomatis '
          'dan bergantung pada hasil pemeriksaan admin.',
    ],
    '6. Hak dan kewajiban pengguna': [
      'Pengguna berhak memperoleh akses terhadap fitur yang tersedia '
          'sesuai dengan perannya.',
      'Pengguna wajib mematuhi ketentuan penggunaan aplikasi '
          'dan menjaga ketertiban dalam menggunakan layanan.',
    ],
    '7. Larangan': [
      'Pengguna dilarang menggunakan aplikasi untuk melakukan tindakan '
          'yang merugikan pengguna lain atau sistem.',
      'Pengguna dilarang memberikan informasi palsu '
          'atau menggunakan akun milik orang lain.',
      'Pengguna dilarang melakukan tindakan yang dapat mengganggu '
          'keamanan dan operasional aplikasi.',
    ],
    '8. Penanganan pelanggaran': [
      'Pelanggaran terhadap ketentuan dapat menyebabkan pembatasan '
          'atau penghentian akses terhadap fitur tertentu.',
      'Tindakan yang diberikan disesuaikan dengan jenis '
          'dan tingkat pelanggaran.',
    ],
    '9. Perubahan ketentuan': [
      'Syarat & Ketentuan dapat diperbarui apabila terdapat perubahan '
          'pada layanan atau kebijakan aplikasi.',
      'Pengguna dianjurkan untuk memeriksa halaman ini secara berkala.',
    ],
    '10. Privasi dan data': [
      'Data pengguna digunakan untuk mendukung penyediaan '
          'layanan aplikasi.',
      'Pengguna bertanggung jawab memastikan data yang diberikan '
          'merupakan data yang benar dan sesuai.',
    ],
    '11. Persetujuan': [
      'Dengan menggunakan aplikasi Kantin Cerdas, pengguna menyatakan '
          'telah membaca, memahami, dan menyetujui Syarat & Ketentuan '
          'yang berlaku.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Syarat dan ketentuan'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const BackButtonIcon(),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.app);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KcSpacing.lg),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ketentuan penggunaan aplikasi Kantin Cerdas '
                      'bagi seluruh pengguna.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: KcSpacing.xs),
                    Text(
                      'Terakhir diperbarui: $_lastUpdated',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: KcSpacing.lg),
                    const Divider(),
                    const SizedBox(height: KcSpacing.lg),
                    for (final section in _sections.entries)
                      _TermsSection(
                        title: section.key,
                        paragraphs: section.value,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: KcSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: KcSpacing.sm),
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: KcSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: KcSpacing.xs),
                  Expanded(
                    child: Text(paragraph, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

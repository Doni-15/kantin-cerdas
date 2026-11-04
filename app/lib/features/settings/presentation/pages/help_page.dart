import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_snack_bar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  static const _contentMaxWidth = 640.0;

  // Konten panduan aplikasi yang dikelola bersama UI.
  static const _guides = <String, String>{
    'Bagaimana cara membuat akun?':
        'Pilih Daftar pada halaman masuk. Isi nama lengkap, email, '
        'password, dan konfirmasi password. Tekan Lanjut, pilih username, '
        'lalu tekan Buat akun. Setelah pendaftaran berhasil, kamu '
        'diarahkan ke halaman masuk.',
    'Apa yang digunakan untuk masuk?':
        'Masukkan username atau email beserta password akunmu. '
        'Jika muncul pesan kesalahan, periksa keterangannya '
        'sebelum mencoba kembali.',
    'Cara memesan makanan':
        'Pilih kantin, pilih makanan yang ingin dipesan, tentukan jumlah '
        'pesanan di keranjang, kemudian lakukan konfirmasi pesanan.',
    'Status pesanan':
        'Buka menu Pesanan untuk melihat status pesanan yang sedang '
        'berlangsung, atau menu Riwayat untuk melihat pesanan yang telah selesai.',
    'Pengajuan kantin (Buka Kantin)':
        'Buka Profil > Ajukan kantin, lengkapi informasi stan yang diperlukan, '
        'kemudian kirim pengajuan untuk diperiksa oleh admin.',
    'Mengelola kantin & menu (Pemilik Kantin)':
        'Pemilik kantin dapat membuka atau menutup stan, menambahkan/mengubah '
        'menu beserta ketersediaannya, dan memproses pesanan yang masuk.',
    'Bagaimana mengubah tema aplikasi?':
        'Buka Pengaturan, lalu pilih Ikuti sistem, Terang, atau Gelap '
        'pada bagian Tema aplikasi. Pilihan diterapkan setelah '
        'berhasil disimpan.',
    'Bagaimana mengganti password?':
        'Buka Keamanan akun, lalu pilih Ubah password. Isi password '
        'saat ini, password baru yang berbeda, dan konfirmasi '
        'password baru. Setelah itu, pilih Simpan password.',
    'Apa yang dilakukan jika sesi gagal dipulihkan?':
        'Pada halaman pemulihan sesi, pilih Coba lagi. Kamu juga '
        'dapat memilih Ke halaman masuk untuk masuk menggunakan akunmu.',
    'Bagaimana keluar dari akun?':
        'Buka Profil, lalu pilih Keluar dari akun dan konfirmasi pada '
        'dialog yang muncul. Setelah logout berhasil, aplikasi '
        'mengarahkanmu ke halaman masuk.',
  };

  final _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final guides = _guides.entries.where((entry) {
      return entry.key.toLowerCase().contains(_query) ||
          entry.value.toLowerCase().contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat bantuan'),
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
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    'Temukan panduan penggunaan KantinCerdas.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: KcSpacing.lg),
                  KcTextField(
                    label: 'Cari panduan',
                    hint: 'Cari akun, password, atau tema',
                    controller: _searchController,
                    prefixIcon: Icons.search,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.close),
                            onPressed: _clearSearch,
                          ),
                    onChanged: (value) {
                      setState(() {
                        _query = value.trim().toLowerCase();
                      });
                    },
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(height: KcSpacing.lg),
                  if (guides.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: KcSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: KcSpacing.md),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              'Panduan tidak ditemukan',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: KcSpacing.xs),
                          Text(
                            'Coba kata kunci lain, seperti akun, '
                            'password, atau tema.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  else
                    for (final entry in guides)
                      Padding(
                        padding: const EdgeInsets.only(bottom: KcSpacing.sm),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            key: PageStorageKey<String>(entry.key),
                            title: Text(
                              entry.key,
                              style: theme.textTheme.titleSmall,
                            ),
                            shape: const Border(),
                            collapsedShape: const Border(),
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: KcSpacing.md,
                              vertical: KcSpacing.xs,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              KcSpacing.md,
                              0,
                              KcSpacing.md,
                              KcSpacing.md,
                            ),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                entry.value,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: KcSpacing.lg),
                  Text(
                    'Masih butuh bantuan?',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: KcSpacing.sm),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email'),
                          subtitle: const Text('Hubungi kami melalui email'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            KcSnackBar.info(
                              context,
                              'Silakan kirim email ke support@kantincerdas.ac.id',
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.chat_outlined),
                          title: const Text('WhatsApp'),
                          subtitle: const Text('Hubungi kami melalui WhatsApp'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            KcSnackBar.info(
                              context,
                              'Layanan bantuan WhatsApp segera tersedia.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class KcTermsPage extends StatelessWidget {
  const KcTermsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Syarat & Ketentuan'),
        centerTitle: true,
        elevation: 0, // Dibuat flat agar menyatu dengan body
      ),
      body: ListView(
        // Padding atas dikurangi karena judul redundan sudah dihapus
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48), 
        children: [
          // Deskripsi singkat dipindah ke atas, dibuat lebih menyatu
          Text(
            'Ketentuan penggunaan aplikasi Kantin Cerdas bagi seluruh pengguna.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Tanggal dibuat lebih elegan dan subtle (redup) tanpa kotak tebal
          Row(
            children: [
              Icon(
                Icons.update_outlined, 
                size: 16, 
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Terakhir diperbarui: 29 September 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic, // Efek miring untuk meta-data
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          const Divider(height: 1), // Garis pemisah tipis pembuka dokumen
          const SizedBox(height: 32),

          const _TermsSection(
            title: '1. Ketentuan Umum',
            contents: [
              'Pengguna wajib membaca dan memahami Syarat & Ketentuan sebelum menggunakan aplikasi.',
              'Dengan menggunakan aplikasi, pengguna dianggap telah memahami dan menyetujui ketentuan yang berlaku.',
            ],
          ),

          const _TermsSection(
            title: '2. Akun Pengguna',
            contents: [
              'Pengguna wajib memberikan informasi akun yang benar dan dapat dipertanggungjawabkan.',
              'Pengguna bertanggung jawab menjaga keamanan akun dan tidak membagikan informasi login kepada pihak lain.',
              'Setiap aktivitas yang dilakukan melalui akun menjadi tanggung jawab pemilik akun.',
            ],
          ),

          const _TermsSection(
            title: '3. Penggunaan Aplikasi',
            contents: [
              'Aplikasi digunakan untuk melakukan pemesanan makanan, melihat informasi kantin, dan menggunakan layanan lain yang tersedia.',
              'Pengguna wajib menggunakan aplikasi secara wajar dan tidak mengganggu operasional sistem.',
            ],
          ),

          const _TermsSection(
            title: '4. Pesanan dan Transaksi',
            contents: [
              'Pengguna bertanggung jawab memastikan informasi pesanan sudah benar sebelum melakukan konfirmasi.',
              'Status pesanan dapat berubah sesuai proses yang dilakukan oleh pihak terkait.',
              'Pembatalan, pembayaran, dan penyelesaian pesanan mengikuti ketentuan layanan yang berlaku.',
            ],
          ),

          const _TermsSection(
            title: '5. Pengajuan Kantin',
            contents: [
              'Pengguna dapat mengajukan pembukaan kantin melalui fitur yang tersedia.',
              'Informasi yang diberikan dalam pengajuan harus benar, lengkap, dan dapat dipertanggungjawabkan.',
              'Setiap pengajuan akan melalui proses pemeriksaan oleh admin.',
              'Persetujuan pengajuan tidak diberikan secara otomatis dan bergantung pada hasil pemeriksaan admin.',
            ],
          ),

          const _TermsSection(
            title: '6. Hak dan Kewajiban Pengguna',
            contents: [
              'Pengguna berhak memperoleh akses terhadap fitur yang tersedia sesuai dengan perannya.',
              'Pengguna wajib mematuhi ketentuan penggunaan aplikasi dan menjaga ketertiban dalam menggunakan layanan.',
            ],
          ),

          const _TermsSection(
            title: '7. Larangan',
            contents: [
              'Pengguna dilarang menggunakan aplikasi untuk melakukan tindakan yang merugikan pengguna lain atau sistem.',
              'Pengguna dilarang memberikan informasi palsu atau menggunakan akun milik orang lain.',
              'Pengguna dilarang melakukan tindakan yang dapat mengganggu keamanan dan operasional aplikasi.',
            ],
          ),

          const _TermsSection(
            title: '8. Penanganan Pelanggaran',
            contents: [
              'Pelanggaran terhadap ketentuan dapat menyebabkan pembatasan atau penghentian akses terhadap fitur tertentu.',
              'Tindakan yang diberikan disesuaikan dengan jenis dan tingkat pelanggaran.',
            ],
          ),

          const _TermsSection(
            title: '9. Perubahan Ketentuan',
            contents: [
              'Syarat & Ketentuan dapat diperbarui apabila terdapat perubahan pada layanan atau kebijakan aplikasi.',
              'Pengguna dianjurkan untuk memeriksa halaman ini secara berkala.',
            ],
          ),

          const _TermsSection(
            title: '10. Privasi dan Data',
            contents: [
              'Data pengguna digunakan untuk mendukung penyediaan layanan aplikasi.',
              'Pengguna bertanggung jawab memastikan data yang diberikan merupakan data yang benar dan sesuai.',
            ],
          ),

          const _TermsSection(
            title: '11. Persetujuan',
            contents: [
              'Dengan menggunakan aplikasi Kantin Cerdas, pengguna menyatakan telah membaca, memahami, dan menyetujui Syarat & Ketentuan yang berlaku.',
            ],
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.title,
    required this.contents,
  });

  final String title;
  final List<String> contents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Padding bawah sedikit ditambah agar pembacaan per bab lebih santai
      padding: const EdgeInsets.only(bottom: 32), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              // Warna dikembalikan ke default onSurface agar lebih elegan dan tidak disangka link
              color: theme.colorScheme.onSurface, 
            ),
          ),
          const SizedBox(height: 12),
          ...contents.map(
            (content) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5, // Disamakan dengan height konten agar lurus vertikal sempurna
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8), // Jarak dirapatkan (dari 12 ke 8)
                  Expanded(
                    child: Text(
                      content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
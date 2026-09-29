import 'package:flutter/material.dart';

enum HelpRole {
  customer,
  owner,
}

// 1. Buat model data sederhana untuk FAQ
class FaqItem {
  final String title;
  final String content;

  const FaqItem({
    required this.title,
    required this.content,
  });
}

class HelpPage extends StatefulWidget {
  const HelpPage({
    super.key,
    required this.role,
  });

  final HelpRole role;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // 2. Simpan data bantuan umum ke dalam List
  final List<FaqItem> _generalFaqs = const [
    FaqItem(
      title: 'Cara menggunakan aplikasi',
      content:
          'Pelajari cara menggunakan berbagai fitur yang tersedia di aplikasi Kantin Cerdas.',
    ),
    FaqItem(
      title: 'FAQ (Pertanyaan Umum)',
      content:
          'Temukan jawaban untuk pertanyaan yang sering diajukan oleh pengguna.',
    ),
    FaqItem(
      title: 'Masalah akun',
      content:
          'Temukan bantuan untuk masalah seperti lupa password, tidak bisa login, dan perubahan informasi akun.',
    ),
  ];

  // 3. Simpan data bantuan sesuai role
  late final List<FaqItem> _roleFaqs;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data role berdasarkan role pengguna yang sedang login
    if (widget.role == HelpRole.customer) {
      _roleFaqs = const [
        FaqItem(
          title: 'Cara memesan makanan',
          content:
              'Pilih kantin, pilih makanan yang ingin dipesan, tentukan jumlah pesanan, kemudian lakukan konfirmasi.',
        ),
        FaqItem(
          title: 'Status pesanan',
          content:
              'Buka menu Pesanan untuk melihat status pesanan yang sedang berlangsung.',
        ),
        FaqItem(
          title: 'Pengajuan kantin',
          content:
              'Buka fitur Buka Kantin, lengkapi informasi yang diperlukan, kemudian kirim pengajuan untuk diperiksa oleh admin.',
        ),
      ];
    } else {
      _roleFaqs = const [
        FaqItem(
          title: 'Mengelola kantin',
          content:
              'Kelola informasi kantin dan pengaturan kantin melalui fitur yang tersedia.',
        ),
        FaqItem(
          title: 'Mengelola menu',
          content:
              'Tambahkan, ubah, atau kelola makanan dan minuman yang tersedia di kantin.',
        ),
        FaqItem(
          title: 'Memproses pesanan',
          content:
              'Periksa pesanan yang masuk dan perbarui status pesanan sesuai proses yang sedang berlangsung.',
        ),
      ];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi cerdas untuk menyaring data berdasarkan pencarian
  List<FaqItem> _getFilteredFaqs(List<FaqItem> faqs) {
    if (_searchQuery.isEmpty) return faqs;

    return faqs.where((faq) {
      final query = _searchQuery.toLowerCase();
      final title = faq.title.toLowerCase();
      final content = faq.content.toLowerCase();
      return title.contains(query) || content.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredGeneral = _getFilteredFaqs(_generalFaqs);
    final filteredRole = _getFilteredFaqs(_roleFaqs);
    
    // Mengecek apakah pencarian tidak menemukan hasil sama sekali
    final isNotFound = _searchQuery.isNotEmpty && filteredGeneral.isEmpty && filteredRole.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Tutup keyboard jika layar diklik
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text(
              'Hai! Ada yang bisa kami bantu?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Kolom Pencarian (Search Bar)
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari topik atau pertanyaan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Tampilkan hasil atau pesan kosong
            if (isNotFound)
              _buildEmptyState(context)
            else ...[
              if (filteredGeneral.isNotEmpty) ...[
                _buildFaqSection('Bantuan Umum', filteredGeneral),
                const SizedBox(height: 32),
              ],
              
              if (filteredRole.isNotEmpty) ...[
                _buildFaqSection(
                  widget.role == HelpRole.customer ? 'Bantuan Customer' : 'Bantuan Owner', 
                  filteredRole,
                ),
                const SizedBox(height: 32),
              ],
            ],

            // Kontak Bantuan selalu ada di paling bawah, baik saat mencari ataupun tidak
            _buildContactHelp(context),
          ],
        ),
      ),
    );
  }
  
  // Widget saat pencarian tidak ditemukan
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Topik tidak ditemukan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba gunakan kata kunci lain atau\nhubungi kami langsung di bawah ini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Builder dinamis untuk FAQ (List diproses otomatis)
  Widget _buildFaqSection(String title, List<FaqItem> items) {
    return _HelpSection(
      title: title,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _HelpItem(
            title: items[i].title,
            content: items[i].content,
          ),
          if (i < items.length - 1) const Divider(height: 1), // Garis tipis otomatis di sela-sela item
        ]
      ],
    );
  }

  Widget _buildContactHelp(BuildContext context) {
    return _HelpSection(
      title: 'Masih butuh bantuan?',
      children: [
        _ContactItem(
          icon: Icons.email_outlined,
          title: 'Email',
          subtitle: 'Hubungi kami melalui email',
          onTap: () {},
        ),
        const Divider(height: 1, indent: 64),
        _ContactItem(
          icon: Icons.chat_outlined,
          title: 'WhatsApp',
          subtitle: 'Hubungi kami melalui WhatsApp',
          onTap: () {},
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// REUSABLE WIDGETS (Sama dengan sebelumnya)
// ----------------------------------------------------------------------------

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          icon,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
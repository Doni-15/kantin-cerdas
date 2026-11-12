/// Standar tunggal kategori menu lintas fitur Customer dan Owner.
enum MenuCategory {
  rice('Nasi'),
  noodles('Mi'),
  drinks('Minuman'),
  snacks('Camilan'),
  other('Lainnya');

  const MenuCategory(this.label);

  final String label;

  /// Mencoba memetakan kategori dari kode backend atau label kanonis tanpa fallback diam-diam.
  static MenuCategory? tryFromRaw(String raw) {
    final normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'rice' || 'nasi' => MenuCategory.rice,
      'noodles' || 'mi' || 'mie' => MenuCategory.noodles,
      'drinks' || 'minuman' => MenuCategory.drinks,
      'snacks' || 'camilan' => MenuCategory.snacks,
      'other' || 'lainnya' => MenuCategory.other,
      _ => null,
    };
  }

  /// Menormalisasi nilai kategori dari kode backend, label UI, maupun ejaan legacy ('Mie' -> 'Mi').
  static MenuCategory fromRaw(String raw) =>
      tryFromRaw(raw) ?? MenuCategory.other;

  /// Mengembalikan label kanonis ('Nasi', 'Mi', 'Minuman', 'Camilan', 'Lainnya')
  /// jika string cocok dengan salah satu kategori standar, atau mempertahankan
  /// string asli yang sudah di-trim bila merupakan kategori kustom.
  static String normalizeLabel(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    return switch (lower) {
      'rice' || 'nasi' => MenuCategory.rice.label,
      'noodles' || 'mi' || 'mie' => MenuCategory.noodles.label,
      'drinks' || 'minuman' => MenuCategory.drinks.label,
      'snacks' || 'camilan' => MenuCategory.snacks.label,
      'other' || 'lainnya' => MenuCategory.other.label,
      _ => trimmed,
    };
  }
}

/// Alias kompatibilitas untuk modul Owner.
typedef OwnerMenuCategory = MenuCategory;

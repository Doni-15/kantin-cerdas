final class EnvConfigException implements Exception {
  final String key;
  final String message;

  const EnvConfigException(
    this.key, 
    this.message
  );

  @override
  String toString() => 'EnvConfigException [$key]: $message';
}

final class EnvParser {
  final Map<String, String?> _source;

  const EnvParser(
    this._source
  );

  String requiredString(String key) {
    final raw = _source[key]?.trim() ?? '';

    if (raw.isEmpty) {
      throw EnvConfigException(
        key,
        'Variabel wajib "$key" belum diisi di konfigurasi environment.',
      );
    }

    if (raw.contains('isi_dari_') || raw.contains('isi_dengan_') || raw == 'changeme') {
      throw EnvConfigException(
        key,
        'Variabel "$key" masih berisi nilai contoh (placeholder). Ganti dengan kunci asli.',
      );
    }

    return raw;
  }

  String optionalString(String key, {String defaultValue = ''}) {
    final raw = _source[key]?.trim() ?? '';
    return raw.isEmpty ? defaultValue : raw;
  }

  int intValue(String key, {required int defaultValue, int? min, int? max,}) {
    final raw = _source[key]?.trim() ?? '';
    final value = raw.isEmpty ? defaultValue : int.tryParse(raw);

    if (value == null) {
      throw EnvConfigException(
        key,
        'Nilai "$raw" bukan bilangan bulat yang valid.',
      );
    }

    if (min != null && value < min) {
      throw EnvConfigException(
        key,
        'Nilai ($value) tidak boleh lebih kecil dari $min.',
      );
    }

    if (max != null && value > max) {
      throw EnvConfigException(
        key,
        'Nilai ($value) tidak boleh lebih besar dari $max.',
      );
    }

    return value;
  }

  bool boolValue(String key, {required bool defaultValue}) {
    final raw = _source[key]?.trim().toLowerCase() ?? '';
    if (raw.isEmpty) return defaultValue;

    switch (raw) {
      case 'true': case '1': case 'yes': return true;
      case 'false': case '0': case 'no': return false;

      default:
        throw EnvConfigException(
          key,
          'Nilai "$raw" bukan boolean valid (gunakan true atau false).',
        );
    }
  }

  String urlString(String key, {String? defaultValue, bool requireHttps = false}) {
    final raw = _source[key]?.trim() ?? '';
    final effective = raw.isEmpty ? (defaultValue?.trim() ?? '') : raw;

    if (effective.isEmpty) {
      throw EnvConfigException(key, 'URL wajib "$key" belum diisi.');
    }

    final uri = Uri.tryParse(effective);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw EnvConfigException(
        key,
        'Nilai "$effective" bukan URL yang valid.',
      );
    }

    final scheme = uri.scheme.toLowerCase();
    if (requireHttps && scheme != 'https') {
      throw EnvConfigException(
        key,
        'URL "$effective" wajib menggunakan skema https://.',
      );
    }

    if (scheme != 'http' && scheme != 'https') {
      throw EnvConfigException(
        key,
        'URL "$effective" harus menggunakan skema http:// atau https://.',
      );
    }

    return effective.endsWith('/')
      ? effective.substring(0, effective.length - 1)
      : effective;
  }

  T enumValue<T extends Enum>(String key, List<T> values, {required T defaultValue,}) {
    final raw = _source[key]?.trim().toLowerCase() ?? '';
    if (raw.isEmpty) return defaultValue;

    for (final item in values) {
      if (item.name.toLowerCase() == raw) {
        return item;
      }
    }

    final allowed = values.map((e) => e.name).join(', ');
    throw EnvConfigException(
      key,
      'Nilai "$raw" tidak valid. Pilihan yang diizinkan: [$allowed].',
    );
  }

  List<String> csvList(String key, {List<String> defaultValue = const [], bool allowEmpty = false,}) {
    final raw = _source[key]?.trim() ?? '';
    final items = raw.isEmpty
      ? defaultValue
      : raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);

    if (!allowEmpty && items.isEmpty) {
      throw EnvConfigException(
        key,
        'Daftar "$key" tidak boleh kosong.',
      );
    }

    return List<String>.unmodifiable(items);
  }
}
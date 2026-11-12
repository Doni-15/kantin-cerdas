/// Konfigurasi environment dan batas waktu komunikasi jaringan aplikasi.
abstract final class AppEnvironment {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get normalizedApiBaseUrl {
    var trimmed = apiBaseUrl.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.trim().isEmpty) {
      return '';
    }
    return trimmed;
  }

  static bool get isApiConfigured => normalizedApiBaseUrl.isNotEmpty;

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const Duration checkoutTimeout = Duration(seconds: 45);
}

/// Informasi versi dan kontak dukungan terpusat agar tidak di-hardcode di banyak halaman.
abstract final class AppBuildInfo {
  static const String version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static const String displayVersion = 'Kantin Cerdas v$version';

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@kantincerdas.ac.id',
  );
}

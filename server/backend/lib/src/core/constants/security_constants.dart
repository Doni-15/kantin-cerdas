abstract final class SecurityConstants {
  // ---------------------------------------------------------------------------
  // Batas ukuran & dimensi gambar
  // ---------------------------------------------------------------------------
  static const int minImageBytes = 32;
  static const int maxImageBytes = 2 * 1024 * 1024;
  static const int maxMultipartEnvelopeBytes = 3 * 1024 * 1024;
  static const int maxDimensionPx = 8192;
  static const int maxTotalPixels = 16 * 1000 * 1000;

  // ---------------------------------------------------------------------------
  // Batas ukuran request
  // ---------------------------------------------------------------------------
  /// Body JSON biasa (login, change-password, dll.).
  static const int maxJsonBodyBytes = 64 * 1024;

  /// Register (avatar Base64 <= 2 MB -> ~2,8 MB) dan upload multipart.
  static const int maxMediaRequestBytes = 4 * 1024 * 1024;

  static const int maxMultipartFieldBytes = 1024;
  static const int maxMultipartParts = 8;

  // ---------------------------------------------------------------------------
  // Media
  // ---------------------------------------------------------------------------
  static const Set<String> allowedCategories = <String>{
    'profile_avatar',
    'menu_photo',
    'stall_photo',
  };

  static final RegExp idempotencyKeyPattern = RegExp(r'^[a-f0-9]{48}$');
  static final RegExp nonSafeActorChars = RegExp(r'[^a-z0-9_-]');

  static final RegExp actorEdgeTrimPattern = RegExp(r'^[-_]+|[-_]+$');

  /// Sisa nama objek setelah prefix `<actor>_<kategori>_`: `<uuid-v4>.<ext>`.
  static final RegExp uuidV4WithExtensionPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$',
  );

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  static final RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9._]+$');
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // ---------------------------------------------------------------------------
  // Pemindaian payload & URL
  // ---------------------------------------------------------------------------
  static const List<String> forbiddenScriptTokens = <String>[
    '<script',
    '</script',
    '<?php',
    // Token '<?=' (hanya 3 byte) sengaja TIDAK dimasukkan: pada data piksel
    // terkompresi peluang kemunculannya acak ~2^-24 per posisi, sehingga
    // sekitar 1% foto 200 KB (dan ~12% foto 2 MB) akan salah ditolak.
    '<svg',
    '<!doctype',
    '<html',
    '<iframe',
    '<object',
    '<embed',
    'javascript:',
    'vbscript:',
    'data:text/html',
    'onerror=',
    'onload=',
  ];

  /// Karakter terlarang di dalam URL gambar: kontrol, spasi, kutip, <, >,
  /// backslash, backtick, dan '@' (mencegah trik userinfo di host).
  static final RegExp unsafeUrlChars = RegExp(r'[\x00-\x20\x7f<">\x27\\`@]');
}

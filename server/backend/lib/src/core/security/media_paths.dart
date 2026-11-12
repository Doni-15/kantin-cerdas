import 'dart:math';

import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';

/// Satu-satunya tempat yang menentukan nama objek di bucket media.
///
/// Format: `<actor>_<kategori>_<uuid-v4>.<ext>`. UUID diturunkan secara
/// deterministik dari `Idempotency-Key`, sehingga retry dengan key yang sama
/// selalu menghasilkan path yang sama (tidak ada file yatim).
abstract final class MediaPaths {
  /// Membersihkan `actorId` menjadi `[a-z0-9_-]` maksimal 32 karakter.
  static String sanitizeActorId(String rawActorId) {
    final cleaned = rawActorId
        .trim()
        .toLowerCase()
        .replaceAll(SecurityConstants.nonSafeActorChars, '')
        .replaceAll(SecurityConstants.actorEdgeTrimPattern, '');
    if (cleaned.isEmpty) {
      throw ApiException.unprocessable(
        'Identitas pengguna tidak valid untuk penamaan media.',
        code: 'INVALID_INPUT',
      );
    }
    return cleaned.length > 32 ? cleaned.substring(0, 32) : cleaned;
  }

  /// Menurunkan UUID v4 dari 48 karakter hex `mutationId`.
  static String uuidFromMutationId(String mutationId) {
    if (!SecurityConstants.idempotencyKeyPattern.hasMatch(mutationId)) {
      throw ArgumentError.value(mutationId, 'mutationId', 'Bukan 48 hex.');
    }
    final h = mutationId.substring(0, 32).split('');
    h[12] = '4';
    h[16] = '89ab'[int.parse(h[16], radix: 16) % 4];
    final s = h.join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-'
        '${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  static String buildObjectPath({
    required String actorId,
    required String category,
    required String mutationId,
    required String extension,
  }) {
    final actor = sanitizeActorId(actorId);
    final uuid = uuidFromMutationId(mutationId);
    return '${actor}_${category}_$uuid.$extension';
  }

  /// Prefix nama objek avatar milik [actorId].
  static String avatarPrefix(String actorId) =>
      '${sanitizeActorId(actorId)}_profile_avatar_';

  /// `true` hanya jika [url] berada di bawah [publicBaseUrl] (host + bucket
  /// terkonfigurasi) DAN nama objeknya adalah avatar milik [actorId].
  static bool isOwnedAvatarUrl(
    String url, {
    required String publicBaseUrl,
    required String actorId,
  }) {
    final base = '$publicBaseUrl/';
    if (!url.startsWith(base)) return false;

    final name = url.substring(base.length);
    final prefix = avatarPrefix(actorId);
    if (!name.startsWith(prefix)) return false;

    return SecurityConstants.uuidV4WithExtensionPattern.hasMatch(
      name.substring(prefix.length),
    );
  }

  /// 48 karakter hex acak (24 byte) sesuai format Idempotency-Key.
  static String generateMutationId48() {
    final random = Random.secure();
    return List<String>.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

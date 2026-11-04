import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';

/// Memvalidasi batas parameter paginasi serta invariansi halaman ber-cursor
/// dari respons backend sesuai kontrak produksi (`SPESIFIKASI_BACKEND.md`).
void validateCursorPageBounds({
  required int limit,
  required String? requestCursor,
  required int itemCount,
  required String? nextCursor,
  int minLimit = 1,
  int maxLimit = 100,
}) {
  if (limit < minLimit || limit > maxLimit) {
    throw const DataParsingException(
      'Batas paginasi (limit) di luar rentang yang diizinkan.',
    );
  }
  if (requestCursor != null && requestCursor.trim().isEmpty) {
    throw const DataParsingException(
      'Cursor permintaan tidak boleh berupa string kosong.',
    );
  }
  if (itemCount < 0 || itemCount > limit) {
    throw DataParsingException(
      'Jumlah item halaman ($itemCount) melebihi batas limit ($limit).',
    );
  }
  if (nextCursor != null) {
    final trimmedNext = nextCursor.trim();
    if (trimmedNext.isEmpty) {
      throw const DataParsingException(
        'Cursor halaman berikutnya tidak boleh kosong.',
      );
    }
    if (requestCursor != null && trimmedNext == requestCursor.trim()) {
      throw const DataParsingException(
        'Cursor halaman berikutnya berulang terhadap cursor permintaan.',
      );
    }
  }
}

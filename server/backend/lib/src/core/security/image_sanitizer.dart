import 'dart:typed_data';

/// Membersihkan metadata & data sisipan dari gambar TANPA re-encode piksel
/// (murah di CPU, tidak mengubah kualitas).
///
/// - JPEG : buang APP1 (EXIF/XMP, termasuk GPS), COM, APP3..APP15 selain Adobe,
///          APP2 selain ICC, serta SELURUH data setelah EOI (mis. trailer video
///          "motion photo" atau payload polyglot). Orientasi EXIF dipertahankan
///          lewat APP1 minimal agar foto HP tidak berputar.
/// - PNG  : buang tEXt/zTXt/iTXt/eXIf/tIME dan data setelah IEND.
/// - WebP : buang chunk EXIF/XMP (orientasi dipertahankan), data setelah RIFF,
///          dan perbaiki ukuran RIFF + flag VP8X.
///
/// Mengembalikan `null` jika struktur berkas rusak.
abstract final class ImageSanitizer {
  static Uint8List? sanitize(Uint8List bytes, String extension) {
    switch (extension) {
      case 'jpg':
        return _sanitizeJpeg(bytes);
      case 'png':
        return _sanitizePng(bytes);
      case 'webp':
        return _sanitizeWebp(bytes);
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // JPEG
  // ---------------------------------------------------------------------------
  static Uint8List? _sanitizeJpeg(Uint8List b) {
    if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;

    final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
    var orientation = 1;
    var orientationDone = false;
    var sawSof = false;
    var wroteOrientation = false;
    var i = 2;

    void writeOrientationIfNeeded() {
      if (!wroteOrientation && orientation > 1) {
        out.add(_orientationApp1(orientation));
      }
      wroteOrientation = true;
    }

    while (i + 1 < b.length) {
      if (b[i] != 0xFF) return null;
      final marker = b[i + 1];
      if (marker == 0xFF) {
        i++; // fill byte
        continue;
      }
      // EOI / SOI / RSTn / TEM / 0x00 sebelum SOS = struktur tidak valid.
      if (marker == 0xD9 ||
          marker == 0xD8 ||
          marker == 0x00 ||
          marker == 0x01 ||
          (marker >= 0xD0 && marker <= 0xD7)) {
        return null;
      }
      if (i + 3 >= b.length) return null;
      final len = (b[i + 2] << 8) | b[i + 3];
      if (len < 2) return null;
      final segEnd = i + 2 + len;
      if (segEnd > b.length) return null;

      if (marker == 0xE1 && !orientationDone) {
        orientation = _jpegExifOrientation(b, i + 4, segEnd) ?? 1;
        if (orientation != 1) orientationDone = true;
      }
      if (_isSof(marker)) sawSof = true;

      if (marker == 0xDA) {
        if (!sawSof) return null;
        final end = _findJpegEnd(b, segEnd);
        if (end < 0) return null;
        writeOrientationIfNeeded();
        out.add(Uint8List.sublistView(b, i, end));
        return out.takeBytes();
      }

      if (_keepJpegSegment(b, marker, i + 4, segEnd)) {
        // APP0 (JFIF) harus tetap tepat setelah SOI.
        if (marker != 0xE0) writeOrientationIfNeeded();
        out.add(Uint8List.sublistView(b, i, segEnd));
      }
      i = segEnd;
    }
    return null;
  }

  static bool _isSof(int m) =>
      m >= 0xC0 && m <= 0xCF && m != 0xC4 && m != 0xC8 && m != 0xCC;

  static bool _keepJpegSegment(Uint8List b, int marker, int start, int end) {
    if (marker == 0xE1 || marker == 0xFE) return false; // EXIF/XMP, komentar
    if (marker == 0xE2) {
      // Pertahankan hanya profil warna ICC ("ICC_PROFILE\0").
      const icc = [
        0x49, 0x43, 0x43, 0x5F, 0x50, 0x52, 0x4F, 0x46, 0x49, 0x4C, 0x45, 0x00,
      ];
      if (end - start < icc.length) return false;
      for (var k = 0; k < icc.length; k++) {
        if (b[start + k] != icc[k]) return false;
      }
      return true;
    }
    if (marker == 0xEE) return true; // APP14 Adobe (transformasi warna)
    if (marker >= 0xE3 && marker <= 0xEF) return false;
    return true; // APP0, DQT, DHT, SOFn, DRI, dll.
  }

  /// Mencari indeks tepat setelah EOI sesudah header SOS. Mendukung JPEG
  /// progresif (beberapa SOS). Mengembalikan -1 bila EOI tidak ditemukan.
  static int _findJpegEnd(Uint8List b, int start) {
    var i = start;
    while (i + 1 < b.length) {
      if (b[i] != 0xFF) {
        i++;
        continue;
      }
      final m = b[i + 1];
      if (m == 0x00 || (m >= 0xD0 && m <= 0xD7)) {
        i += 2;
        continue;
      }
      if (m == 0xFF) {
        i++;
        continue;
      }
      if (m == 0xD9) return i + 2;
      if (i + 3 >= b.length) return -1;
      final len = (b[i + 2] << 8) | b[i + 3];
      if (len < 2) return -1;
      i += 2 + len;
    }
    return -1;
  }

  static int? _jpegExifOrientation(Uint8List b, int start, int end) {
    if (end - start < 14) return null;
    const exif = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
    for (var k = 0; k < exif.length; k++) {
      if (b[start + k] != exif[k]) return null;
    }
    return _tiffOrientation(b, start + 6, end);
  }

  // ---------------------------------------------------------------------------
  // PNG
  // ---------------------------------------------------------------------------
  static const Set<String> _pngDrop = {'tEXt', 'zTXt', 'iTXt', 'eXIf', 'tIME'};

  static Uint8List? _sanitizePng(Uint8List b) {
    if (b.length < 33) return null;
    final out = BytesBuilder(copy: false)..add(Uint8List.sublistView(b, 0, 8));
    var i = 8;
    var first = true;
    var sawIdat = false;

    while (i + 12 <= b.length) {
      final len = (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
      final end = i + 12 + len;
      if (end > b.length) return null;

      final type = String.fromCharCodes(b.sublist(i + 4, i + 8));
      if (first && type != 'IHDR') return null;
      first = false;
      if (type == 'IDAT') sawIdat = true;

      if (!_pngDrop.contains(type)) {
        out.add(Uint8List.sublistView(b, i, end));
      }
      if (type == 'IEND') return sawIdat ? out.takeBytes() : null;
      i = end;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // WebP
  // ---------------------------------------------------------------------------
  static Uint8List? _sanitizeWebp(Uint8List b) {
    if (b.length < 20) return null;
    final riffSize = b[4] | (b[5] << 8) | (b[6] << 16) | (b[7] << 24);
    final riffEnd = 8 + riffSize;
    if (riffEnd > b.length || riffEnd < 20) return null;

    final chunks = BytesBuilder(copy: false);
    var orientation = 1;
    var hasVp8x = false;
    var i = 12;

    while (i + 8 <= riffEnd) {
      final type = String.fromCharCodes(b.sublist(i, i + 4));
      final size = b[i + 4] | (b[i + 5] << 8) | (b[i + 6] << 16) | (b[i + 7] << 24);
      final end = i + 8 + size + (size & 1);
      if (end > riffEnd) return null;

      if (type == 'EXIF') {
        var s = i + 8;
        // Beberapa encoder menaruh awalan "Exif\0\0" sebelum header TIFF.
        if (size >= 6 &&
            b[s] == 0x45 &&
            b[s + 1] == 0x78 &&
            b[s + 2] == 0x69 &&
            b[s + 3] == 0x66) {
          s += 6;
        }
        orientation = _tiffOrientation(b, s, i + 8 + size) ?? 1;
      } else if (type == 'XMP ') {
        // dibuang
      } else if (type == 'VP8X') {
        if (size < 10 || i != 12) return null;
        hasVp8x = true;
        final copy = Uint8List.fromList(Uint8List.sublistView(b, i, end));
        copy[8] = copy[8] & ~0x0C; // bersihkan flag EXIF (0x08) & XMP (0x04)
        chunks.add(copy);
      } else {
        chunks.add(Uint8List.sublistView(b, i, end));
      }
      i = end;
    }
    if (i != riffEnd) return null;

    var body = chunks.takeBytes();
    if (hasVp8x && orientation > 1) {
      final tiff = _orientationTiff(orientation);
      final exifChunk = <int>[
        0x45, 0x58, 0x49, 0x46, // "EXIF"
        tiff.length, 0, 0, 0,
        ...tiff,
      ];
      final merged = Uint8List(body.length + exifChunk.length)
        ..setRange(0, body.length, body)
        ..setRange(body.length, body.length + exifChunk.length, exifChunk);
      body = merged;
      // Set flag EXIF pada VP8X (chunk pertama setelah "WEBP", flag di offset 8).
      body[8] = body[8] | 0x08;
    }

    final total = 4 + body.length;
    final out = Uint8List(8 + total);
    out.setRange(0, 4, const [0x52, 0x49, 0x46, 0x46]); // RIFF
    out[4] = total & 0xFF;
    out[5] = (total >> 8) & 0xFF;
    out[6] = (total >> 16) & 0xFF;
    out[7] = (total >> 24) & 0xFF;
    out.setRange(8, 12, const [0x57, 0x45, 0x42, 0x50]); // WEBP
    out.setRange(12, 12 + body.length, body);
    return out;
  }

  // ---------------------------------------------------------------------------
  // EXIF orientasi (dipakai JPEG & WebP)
  // ---------------------------------------------------------------------------
  static int? _tiffOrientation(Uint8List b, int t, int end) {
    if (t < 0 || end > b.length || end - t < 8) return null;
    final bool le;
    if (b[t] == 0x49 && b[t + 1] == 0x49) {
      le = true;
    } else if (b[t] == 0x4D && b[t + 1] == 0x4D) {
      le = false;
    } else {
      return null;
    }

    int u16(int o) => le ? b[o] | (b[o + 1] << 8) : (b[o] << 8) | b[o + 1];
    int u32(int o) => le
        ? b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)
        : (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

    if (u16(t + 2) != 42) return null;
    final ifd = t + u32(t + 4);
    if (ifd < t + 8 || ifd + 2 > end) return null;

    final count = u16(ifd);
    for (var n = 0; n < count; n++) {
      final e = ifd + 2 + n * 12;
      if (e + 12 > end) return null;
      if (u16(e) == 0x0112) {
        final v = u16(e + 8);
        return (v >= 1 && v <= 8) ? v : null;
      }
    }
    return null;
  }

  /// TIFF minimal (big-endian) yang hanya berisi tag Orientation.
  static List<int> _orientationTiff(int o) => <int>[
        0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // header, IFD @ 8
        0x00, 0x01, // 1 entri
        0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, o, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // IFD berikutnya: tidak ada
      ];

  static List<int> _orientationApp1(int o) => <int>[
        0xFF, 0xE1, 0x00, 0x22, // APP1, panjang 34
        0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
        ..._orientationTiff(o),
      ];
}

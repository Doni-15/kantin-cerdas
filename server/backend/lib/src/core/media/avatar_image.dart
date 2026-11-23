import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

const maxAvatarInputBytes = 2 * 1024 * 1024;
const _maxSide = 4096;
const _maxPixels = _maxSide * _maxSide;
const _thumbnailSide = 512;

Future<Uint8List?> normalizeAvatar(Uint8List bytes, String mediaType) =>
    Isolate.run(() => _normalize(bytes, mediaType));

Uint8List? _normalize(Uint8List bytes, String mediaType) {
  try {
    if (bytes.isEmpty || bytes.length > maxAvatarInputBytes) return null;

    final image.Decoder decoder = switch (mediaType) {
      'image/jpeg' => image.JpegDecoder(maxPixels: _maxPixels),
      'image/png' => image.PngDecoder(maxPixels: _maxPixels),
      'image/webp' => image.WebPDecoder()..maxPixels = _maxPixels,
      _ => throw const FormatException('Unsupported image'),
    };

    final source = mediaType == 'image/png' ? _restrictedPng(bytes) : bytes;
    final info = decoder.startDecode(source);

    // For a still WebP, numFrames counts animation chunks and is zero.
    final animated = decoder is image.WebPDecoder
        ? decoder.info?.hasAnimation == true
        : (info?.numFrames ?? 0) > 1;

    if (info == null || !_sizeAllowed(info.width, info.height) || animated) {
      return null;
    }

    final decoded = decoder.decodeFrame(0);
    if (decoded == null) return null;

    final oriented = image.bakeOrientation(decoded);
    final resized = switch ((oriented.width, oriented.height)) {
      (final width, final height)
          when width > _thumbnailSide && width >= height =>
        image.copyResize(oriented, width: _thumbnailSide),

      (_, final height) when height > _thumbnailSide => image.copyResize(
        oriented,
        height: _thumbnailSide,
      ),
      _ => oriented,
    };

    // A new RGB image discards metadata and flattens input transparency.
    final output = image.Image(width: resized.width, height: resized.height);
    image.fill(output, color: image.ColorRgb8(255, 255, 255));
    image.compositeImage(output, resized);
    return image.encodeJpg(output, quality: 85);
  } on image.ImageException {
    return null;
  } on FormatException {
    return null;
  } on RangeError {
    return null;
  }
}

bool _sizeAllowed(int width, int height) =>
    width > 0 && height > 0 && width <= _maxSide && height <= _maxSide;

Uint8List _restrictedPng(Uint8List bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];

  if (bytes.length < 33 ||
      !Iterable<int>.generate(
        8,
      ).every((index) => bytes[index] == signature[index])) {
    throw const FormatException('Invalid PNG header');
  }

  final data = ByteData.sublistView(bytes);
  if (data.getUint32(8) != 13 ||
      String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') {
    throw const FormatException('Missing image header');
  }

  final width = data.getUint32(16);
  final height = data.getUint32(20);
  if (!_sizeAllowed(width, height)) {
    throw const FormatException('Image too large');
  }

  // Limit the inflater's output to the largest legitimate scanline footprint.
  // RGBA16 uses 8 bytes per pixel; the margin covers Adam7 row filter bytes.
  final inflater = ZLibDecoder().startChunkedConversion(
    _InflationLimit(width * height * 8 + 7 * height + 16),
  );

  final sanitized = BytesBuilder(copy: false)..add(signature);
  var offset = 8;
  var sawImageData = false;

  while (offset + 12 <= bytes.length) {
    final length = data.getUint32(offset);
    final end = offset + length + 12;

    if (end > bytes.length) throw const FormatException('Truncated PNG chunk');
    final type = String.fromCharCodes(
      Uint8List.sublistView(bytes, offset + 4, offset + 8),
    );

    if (type == 'acTL' || type == 'fcTL' || type == 'fdAT') {
      throw const FormatException('Animated image');
    }

    const kept = {'IHDR', 'PLTE', 'IDAT', 'tRNS', 'IEND'};

    if (kept.contains(type)) {
      sanitized.add(Uint8List.sublistView(bytes, offset, end));
    } else if ((bytes[offset + 4] & 32) == 0) {
      throw const FormatException('Unknown critical PNG chunk');
    }

    if (type == 'IDAT') {
      sawImageData = true;
      inflater.add(
        Uint8List.sublistView(bytes, offset + 8, offset + 8 + length),
      );
    }

    if (type == 'IEND' && sawImageData) {
      inflater.close();
      return sanitized.takeBytes();
    }
    offset = end;
  }
  throw const FormatException('Incomplete PNG image');
}

class _InflationLimit extends ByteConversionSinkBase {
  _InflationLimit(this._remaining);
  int _remaining;

  @override
  void add(List<int> chunk) {
    _remaining -= chunk.length;
    if (_remaining < 0) throw const FormatException('Inflated image too large');
  }

  @override
  void close() {}
}

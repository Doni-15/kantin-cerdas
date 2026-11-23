import 'dart:convert';
import 'dart:typed_data';

/// Parsed RSA private key parameters `(modulus, privateExponent)` for RS256.
class RsaPrivateKeyMaterial {
  const RsaPrivateKeyMaterial({
    required this.modulus,
    required this.privateExponent,
  });

  final BigInt modulus;
  final BigInt privateExponent;

  int get modulusByteLength => (modulus.bitLength + 7) ~/ 8;

  /// Parses PEM-encoded PKCS#8 or PKCS#1 RSA private keys without third-party packages.
  factory RsaPrivateKeyMaterial.fromPem(String pem) {
    final lines = pem
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('-----'))
        .join();
    if (lines.isEmpty) {
      throw const FormatException('Empty PEM private key material.');
    }
    final der = base64Decode(lines);
    return RsaPrivateKeyMaterial.fromDer(der);
  }

  factory RsaPrivateKeyMaterial.fromDer(Uint8List der) {
    final reader = _DerReader(der);
    final outer = reader.readSequence();
    final firstTag = outer.peekTag();
    if (firstTag != 0x02) {
      throw const FormatException('Expected ASN.1 INTEGER version.');
    }
    outer.readInteger(); // version

    // PKCS#8: SEQUENCE { version, AlgorithmIdentifier (0x30), OCTET STRING (0x04) }
    if (outer.hasMore && outer.peekTag() == 0x30) {
      outer.readSequence(); // AlgorithmIdentifier
      final innerBytes = outer.readOctetString();
      final pkcs1 = _DerReader(innerBytes).readSequence();
      pkcs1.readInteger(); // PKCS#1 version
      final n = pkcs1.readInteger();
      pkcs1.readInteger(); // e
      final d = pkcs1.readInteger();
      return RsaPrivateKeyMaterial(modulus: n, privateExponent: d);
    }

    // PKCS#1: SEQUENCE { version, n, e, d, ... }
    final n = outer.readInteger();
    outer.readInteger(); // e
    final d = outer.readInteger();
    return RsaPrivateKeyMaterial(modulus: n, privateExponent: d);
  }
}

/// Pure-Dart RSASSA-PKCS1-v1_5 + SHA-256 signature bytes.
Uint8List signRs256Bytes(Uint8List message, RsaPrivateKeyMaterial key) {
  final k = key.modulusByteLength;
  final hash = sha256Digest(message);
  final t = Uint8List(_sha256DigestInfoPrefix.length + hash.length)
    ..setAll(0, _sha256DigestInfoPrefix)
    ..setAll(_sha256DigestInfoPrefix.length, hash);
  if (k < t.length + 11) {
    throw const FormatException(
      'RSA modulus too short for SHA-256 PKCS#1 v1.5.',
    );
  }
  final psLength = k - t.length - 3;
  final em = Uint8List(k);
  em[0] = 0x00;
  em[1] = 0x01;
  em.fillRange(2, 2 + psLength, 0xff);
  em[2 + psLength] = 0x00;
  em.setAll(3 + psLength, t);

  final m = _bytesToBigInt(em);
  final s = m.modPow(key.privateExponent, key.modulus);
  return _bigIntToBytes(s, k);
}

// DER prefix for DigestInfo(SHA-256) per RFC 8017 §9.2.
const List<int> _sha256DigestInfoPrefix = <int>[
  0x30,
  0x31,
  0x30,
  0x0d,
  0x06,
  0x09,
  0x60,
  0x86,
  0x48,
  0x01,
  0x65,
  0x03,
  0x04,
  0x02,
  0x01,
  0x05,
  0x00,
  0x04,
  0x20,
];

BigInt _bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

Uint8List _bigIntToBytes(BigInt value, int length) {
  final out = Uint8List(length);
  var current = value;
  for (var i = length - 1; i >= 0; i--) {
    out[i] = (current & BigInt.from(0xff)).toInt();
    current = current >> 8;
  }
  return out;
}

/// Pure-Dart FIPS 180-4 SHA-256 digest.
Uint8List sha256Digest(Uint8List data) {
  const k = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  var h0 = 0x6a09e667;
  var h1 = 0xbb67ae85;
  var h2 = 0x3c6ef372;
  var h3 = 0xa54ff53a;
  var h4 = 0x510e527f;
  var h5 = 0x9b05688c;
  var h6 = 0x1f83d9ab;
  var h7 = 0x5be0cd19;

  final bitLen = data.length * 8;
  final paddedLen = ((data.length + 9 + 63) ~/ 64) * 64;
  final padded = Uint8List(paddedLen)..setAll(0, data);
  padded[data.length] = 0x80;
  final view = ByteData.sublistView(padded);
  view.setUint32(paddedLen - 8, (bitLen >> 32) & 0xffffffff);
  view.setUint32(paddedLen - 4, bitLen & 0xffffffff);

  final w = Uint32List(64);
  for (var offset = 0; offset < paddedLen; offset += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = view.getUint32(offset + i * 4);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }

    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;
    var f = h5;
    var g = h6;
    var h = h7;

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & 0xffffffff) & g);
      final temp1 = (h + s1 + ch + k[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xffffffff;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xffffffff;
    }

    h0 = (h0 + a) & 0xffffffff;
    h1 = (h1 + b) & 0xffffffff;
    h2 = (h2 + c) & 0xffffffff;
    h3 = (h3 + d) & 0xffffffff;
    h4 = (h4 + e) & 0xffffffff;
    h5 = (h5 + f) & 0xffffffff;
    h6 = (h6 + g) & 0xffffffff;
    h7 = (h7 + h) & 0xffffffff;
  }

  final out = Uint8List(32);
  final outView = ByteData.sublistView(out);
  outView.setUint32(0, h0);
  outView.setUint32(4, h1);
  outView.setUint32(8, h2);
  outView.setUint32(12, h3);
  outView.setUint32(16, h4);
  outView.setUint32(20, h5);
  outView.setUint32(24, h6);
  outView.setUint32(28, h7);
  return out;
}

int _rotr(int value, int bits) =>
    ((value >>> bits) | ((value << (32 - bits)) & 0xffffffff)) & 0xffffffff;

class _DerReader {
  _DerReader(this._bytes);

  final Uint8List _bytes;
  var _pos = 0;

  bool get hasMore => _pos < _bytes.length;

  int peekTag() {
    if (!hasMore) throw const FormatException('Unexpected end of DER input.');
    return _bytes[_pos];
  }

  _DerReader readSequence() => _DerReader(_readTlv(0x30));

  Uint8List readOctetString() => _readTlv(0x04);

  BigInt readInteger() {
    final content = _readTlv(0x02);
    if (content.isEmpty) {
      throw const FormatException('Empty ASN.1 INTEGER.');
    }
    return _bytesToBigInt(content);
  }

  Uint8List _readTlv(int expectedTag) {
    if (!hasMore) throw const FormatException('Unexpected end of DER TLV.');
    final tag = _bytes[_pos++];
    if (tag != expectedTag) {
      throw FormatException('Unexpected ASN.1 tag: $tag != $expectedTag');
    }
    final length = _readLength();
    if (_pos + length > _bytes.length) {
      throw const FormatException('Truncated ASN.1 DER value.');
    }
    final slice = Uint8List.sublistView(_bytes, _pos, _pos + length);
    _pos += length;
    return slice;
  }

  int _readLength() {
    if (!hasMore) throw const FormatException('Unexpected end of DER length.');
    final first = _bytes[_pos++];
    if ((first & 0x80) == 0) return first;
    final byteCount = first & 0x7f;
    if (byteCount == 0 || byteCount > 4 || _pos + byteCount > _bytes.length) {
      throw const FormatException('Unsupported ASN.1 DER length encoding.');
    }
    var length = 0;
    for (var i = 0; i < byteCount; i++) {
      length = (length << 8) | _bytes[_pos++];
    }
    return length;
  }
}

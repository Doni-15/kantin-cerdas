/// Pure-Dart ISO/IEC 15417 Code 128 (Code Set B) encoder & round-trip decoder
/// for preserving leading zeros on order numbers (BARCODE-TECH-001).
class Code128Encoded {
  const Code128Encoded({
    required this.data,
    required this.codes,
    required this.widths,
    required this.modules,
  });

  final String data;
  final List<int> codes;
  final List<int> widths;
  final List<bool> modules;
}

abstract final class Code128Encoder {
  static const int startB = 104;
  static const int stop = 106;

  static const List<List<int>> _patterns = [
    [2, 1, 2, 2, 2, 2], // 0
    [2, 2, 2, 1, 2, 2], // 1
    [2, 2, 2, 2, 2, 1], // 2
    [1, 2, 1, 2, 2, 3], // 3
    [1, 2, 1, 3, 2, 2], // 4
    [1, 3, 1, 2, 2, 2], // 5
    [1, 2, 2, 2, 1, 3], // 6
    [1, 2, 2, 3, 1, 2], // 7
    [1, 3, 2, 2, 1, 2], // 8
    [2, 2, 1, 2, 1, 3], // 9
    [2, 2, 1, 3, 1, 2], // 10
    [2, 3, 1, 2, 1, 2], // 11
    [1, 1, 2, 2, 3, 2], // 12
    [1, 2, 2, 1, 3, 2], // 13
    [1, 2, 2, 2, 3, 1], // 14
    [1, 1, 3, 2, 2, 2], // 15
    [1, 2, 3, 1, 2, 2], // 16
    [1, 2, 3, 2, 2, 1], // 17
    [2, 2, 3, 2, 1, 1], // 18
    [2, 2, 1, 1, 3, 2], // 19
    [2, 2, 1, 2, 3, 1], // 20
    [2, 1, 3, 2, 1, 2], // 21
    [2, 2, 3, 1, 1, 2], // 22
    [3, 1, 2, 1, 3, 1], // 23
    [3, 1, 1, 2, 2, 2], // 24
    [3, 2, 1, 1, 2, 2], // 25
    [3, 2, 1, 2, 2, 1], // 26
    [3, 1, 2, 2, 1, 2], // 27
    [3, 2, 2, 1, 1, 2], // 28
    [3, 2, 2, 2, 1, 1], // 29
    [2, 1, 2, 1, 2, 3], // 30
    [2, 1, 2, 3, 2, 1], // 31
    [2, 3, 2, 1, 2, 1], // 32
    [1, 1, 1, 3, 2, 3], // 33
    [1, 3, 1, 1, 2, 3], // 34
    [1, 3, 1, 3, 2, 1], // 35
    [1, 1, 2, 3, 1, 3], // 36
    [1, 3, 2, 1, 1, 3], // 37
    [1, 3, 2, 3, 1, 1], // 38
    [2, 1, 1, 3, 1, 3], // 39
    [2, 3, 1, 1, 1, 3], // 40
    [2, 3, 1, 3, 1, 1], // 41
    [1, 1, 2, 1, 3, 3], // 42
    [1, 1, 2, 3, 3, 1], // 43
    [1, 3, 2, 1, 3, 1], // 44
    [1, 1, 3, 1, 2, 3], // 45
    [1, 1, 3, 3, 2, 1], // 46
    [1, 3, 3, 1, 2, 1], // 47
    [3, 1, 3, 1, 2, 1], // 48
    [2, 1, 1, 3, 3, 1], // 49
    [2, 3, 1, 1, 3, 1], // 50
    [2, 1, 3, 1, 1, 3], // 51
    [2, 1, 3, 3, 1, 1], // 52
    [2, 1, 3, 1, 3, 1], // 53
    [3, 1, 1, 1, 2, 3], // 54
    [3, 1, 1, 3, 2, 1], // 55
    [3, 3, 1, 1, 2, 1], // 56
    [3, 1, 2, 1, 1, 3], // 57
    [3, 1, 2, 3, 1, 1], // 58
    [3, 3, 2, 1, 1, 1], // 59
    [3, 1, 4, 1, 1, 1], // 60
    [2, 2, 1, 4, 1, 1], // 61
    [4, 3, 1, 1, 1, 1], // 62
    [1, 1, 1, 2, 2, 4], // 63
    [1, 1, 1, 4, 2, 2], // 64
    [1, 2, 1, 1, 2, 4], // 65
    [1, 2, 1, 4, 2, 1], // 66
    [1, 4, 1, 1, 2, 2], // 67
    [1, 4, 1, 2, 2, 1], // 68
    [1, 1, 2, 2, 1, 4], // 69
    [1, 1, 2, 4, 1, 2], // 70
    [1, 2, 2, 1, 1, 4], // 71
    [1, 2, 2, 4, 1, 1], // 72
    [1, 4, 2, 1, 1, 2], // 73
    [1, 4, 2, 2, 1, 1], // 74
    [2, 4, 1, 2, 1, 1], // 75
    [2, 2, 1, 1, 1, 4], // 76
    [4, 1, 3, 1, 1, 1], // 77
    [2, 4, 1, 1, 1, 2], // 78
    [1, 3, 4, 1, 1, 1], // 79
    [1, 1, 1, 2, 4, 2], // 80
    [1, 2, 1, 1, 4, 2], // 81
    [1, 2, 1, 2, 4, 1], // 82
    [1, 1, 4, 2, 1, 2], // 83
    [1, 2, 4, 1, 1, 2], // 84
    [1, 2, 4, 2, 1, 1], // 85
    [4, 1, 1, 2, 1, 2], // 86
    [4, 2, 1, 1, 1, 2], // 87
    [4, 2, 1, 2, 1, 1], // 88
    [2, 1, 2, 1, 4, 1], // 89
    [2, 1, 4, 1, 2, 1], // 90
    [4, 1, 2, 1, 2, 1], // 91
    [1, 1, 1, 1, 4, 3], // 92
    [1, 1, 1, 3, 4, 1], // 93
    [1, 3, 1, 1, 4, 1], // 94
    [1, 1, 4, 1, 1, 3], // 95
    [1, 1, 4, 3, 1, 1], // 96
    [4, 1, 1, 1, 1, 3], // 97
    [4, 1, 1, 3, 1, 1], // 98
    [1, 1, 3, 1, 4, 1], // 99
    [1, 1, 4, 1, 3, 1], // 100
    [3, 1, 1, 1, 4, 1], // 101
    [4, 1, 1, 1, 3, 1], // 102
    [2, 1, 1, 4, 1, 2], // 103 Start A
    [2, 1, 1, 2, 1, 4], // 104 Start B
    [2, 1, 1, 2, 3, 2], // 105 Start C
    [2, 3, 3, 1, 1, 1, 2], // 106 Stop (13 modules)
  ];

  static Code128Encoded encodeCodeB(String input) {
    if (input.isEmpty) {
      throw const FormatException('Code 128 input must not be empty');
    }
    final codes = <int>[startB];
    var weightedSum = startB;
    for (var i = 0; i < input.length; i++) {
      final unit = input.codeUnitAt(i);
      if (unit < 32 || unit > 126) {
        throw FormatException('Unsupported Code 128B character at $i');
      }
      final val = unit - 32;
      codes.add(val);
      weightedSum += val * (i + 1);
    }
    final checksum = weightedSum % 103;
    codes.add(checksum);
    codes.add(stop);

    final widths = <int>[];
    final modules = <bool>[];
    for (final code in codes) {
      final pattern = _patterns[code];
      widths.addAll(pattern);
      var isBar = true;
      for (final run in pattern) {
        for (var j = 0; j < run; j++) {
          modules.add(isBar);
        }
        isBar = !isBar;
      }
    }

    return Code128Encoded(
      data: input,
      codes: List<int>.unmodifiable(codes),
      widths: List<int>.unmodifiable(widths),
      modules: List<bool>.unmodifiable(modules),
    );
  }

  /// Decodes a Code 128B module stream and verifies Modulo 103 checksum.
  static String decodeCodeBModules(List<bool> modules) {
    final runs = <int>[];
    var idx = 0;
    while (idx < modules.length) {
      final color = modules[idx];
      var count = 0;
      while (idx < modules.length && modules[idx] == color) {
        count++;
        idx++;
      }
      runs.add(count);
    }

    if (runs.length < 19 || (runs.length - 1) % 6 != 0) {
      throw const FormatException('Invalid Code 128 run count');
    }
    final symbolCount = (runs.length - 7) ~/ 6;
    final codes = <int>[];
    for (var i = 0; i < symbolCount; i++) {
      final chunk = runs.sublist(i * 6, i * 6 + 6);
      final match = _findSymbol(chunk);
      if (match == null) throw FormatException('Unknown symbol at $i');
      codes.add(match);
    }
    final stopChunk = runs.sublist(symbolCount * 6);
    if (_findSymbol(stopChunk) != stop) {
      throw const FormatException('Missing Code 128 Stop symbol');
    }
    if (codes.first != startB || codes.length < 3) {
      throw const FormatException('Missing Code 128 Start B symbol');
    }

    final checkCode = codes.last;
    var weighted = codes.first;
    final chars = StringBuffer();
    for (var pos = 1; pos < codes.length - 1; pos++) {
      final val = codes[pos];
      if (val > 94) {
        throw FormatException('Non-data Code B value $val');
      }
      weighted += val * pos;
      chars.writeCharCode(val + 32);
    }
    if (weighted % 103 != checkCode) {
      throw const FormatException('Code 128 checksum mismatch');
    }
    return chars.toString();
  }

  static int? _findSymbol(List<int> run) {
    for (var code = 0; code < _patterns.length; code++) {
      final pat = _patterns[code];
      if (pat.length != run.length) continue;
      var same = true;
      for (var i = 0; i < pat.length; i++) {
        if (pat[i] != run[i]) {
          same = false;
          break;
        }
      }
      if (same) return code;
    }
    return null;
  }
}

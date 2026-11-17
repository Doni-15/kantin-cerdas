import 'dart:io';

class EnvConfig {
  EnvConfig(Map<String, String> values) : _values = Map.unmodifiable(values);

  final Map<String, String> _values;

  String? operator [](String key) => _values[key];
  bool contains(String key) => _values.containsKey(key);

  /// Membuat konfigurasi dari Map, berguna untuk unit test.
  factory EnvConfig.fromMap(Map<String, String> values) {
    return EnvConfig(values);
  }

  /// Membaca file .env lalu menggabungkannya dengan environment sistem.
  static Future<EnvConfig> load({
    String envFilePath = '.env',
    Map<String, String>? systemEnvironment,
  }) async {
    final file = File(envFilePath);
    final fileValues = <String, String>{};

    if (await file.exists()) {
      final lines = await file.readAsLines();

      for (var index = 0; index < lines.length; index++) {
        final lineNumber = index + 1;
        var line = lines[index].trim();

        if (index == 0 && line.startsWith('\uFEFF')) {
          line = line.substring(1).trim();
        }

        if (line.isEmpty || line.startsWith('#')) {
          continue;
        }

        if (line.startsWith('export ')) {
          line = line.substring(7).trim();
        }

        final separator = line.indexOf('=');

        if (separator <= 0) {
          throw FormatException(
            'Format .env tidak valid pada baris $lineNumber.',
          );
        }

        final key = line.substring(0, separator).trim();
        final rawValue = line.substring(separator + 1).trim();

        if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) {
          throw FormatException(
            'Nama variabel .env tidak valid pada baris $lineNumber.',
          );
        }

        if (fileValues.containsKey(key)) {
          throw FormatException(
            'Variabel $key didefinisikan lebih dari sekali '
            'pada file .env.',
          );
        }

        fileValues[key] = _parseValue(rawValue, lineNumber: lineNumber);
      }
    }

    final systemValues = systemEnvironment ?? Platform.environment;

    return EnvConfig({...fileValues, ...systemValues});
  }

  static String _parseValue(String value, {required int lineNumber}) {
    if (value.isEmpty) {
      return '';
    }

    final first = value[0];

    if (first != '"' && first != "'") {
      return value;
    }

    if (value.length < 2 || value[value.length - 1] != first) {
      throw FormatException(
        'Nilai .env memiliki tanda kutip tidak berpasangan '
        'pada baris $lineNumber.',
      );
    }

    return value.substring(1, value.length - 1);
  }
}

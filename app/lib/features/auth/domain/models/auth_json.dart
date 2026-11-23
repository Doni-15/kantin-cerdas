Map<String, dynamic> authJsonObject(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Expected JSON object');
}

String requiredAuthText(Map<String, dynamic> json, String key) {
  final value = optionalAuthText(json, key);
  if (value == null) throw FormatException('Missing $key');
  return value;
}

String? optionalAuthText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Invalid $key');
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool listEqualsValue<T>(List<T>? a, List<T>? b) => listEquals(a, b);

bool mapEqualsValue<K, V>(Map<K, V>? a, Map<K, V>? b) => mapEquals(a, b);

int listHashValue<T>(Iterable<T> items) => Object.hashAll(items);

int mapHashValue<K, V>(Map<K, V> map) {
  var hash = 0;
  for (final entry in map.entries) {
    hash ^= Object.hash(entry.key, entry.value);
  }
  return Object.hash(map.length, hash);
}

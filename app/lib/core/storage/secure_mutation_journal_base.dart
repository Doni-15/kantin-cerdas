import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kelas dasar generik untuk seluruh write-ahead mutation journal berbasis FlutterSecureStorage.
/// Menyeragamkan antrean serial, pengodean key per akun, dan versi schema JSON.
abstract class SecureMutationJournalBase<TPending> {
  SecureMutationJournalBase(this._storage);

  final FlutterSecureStorage _storage;
  Future<void> _queue = Future<void>.value();

  String get keyPrefix;
  String get invalidMarkerMessage;
  String get alreadyPendingMessage;
  bool get allowSameMutationOverwrite => false;

  String actorIdOf(TPending pending);
  String mutationIdOf(TPending pending);
  TPending decodeEntry(String actorId, Map<String, Object?> data);
  Map<String, Object?> encodeEntry(TPending pending);

  String storageKey(String actorId) =>
      '$keyPrefix.${base64Url.encode(utf8.encode(actorId))}';

  /// Mendukung pembacaan schema lama ('schema': 1) sekaligus standar baru ('version': 1).
  static bool isSupportedVersion(Map<String, Object?> data) =>
      data['version'] == 1 || data['schema'] == 1;

  Future<TPending?> readEntry(String actorId) =>
      serial(() => readUnlocked(actorId));

  Future<TPending?> readUnlocked(String actorId) async {
    final raw = await _storage.read(key: storageKey(actorId));
    if (raw == null) {
      return null;
    }
    final Object? data = jsonDecode(raw);
    if (data is! Map<Object?, Object?>) {
      throw FormatException(invalidMarkerMessage);
    }
    final map = Map<String, Object?>.from(data);
    if (!isSupportedVersion(map)) {
      throw FormatException(invalidMarkerMessage);
    }
    try {
      return decodeEntry(actorId, map);
    } on ArgumentError {
      throw FormatException(invalidMarkerMessage);
    }
  }

  Future<void> saveEntry(TPending pending) => serial(() async {
    final actorId = actorIdOf(pending);
    final current = await readUnlocked(actorId);
    if (current != null) {
      if (!allowSameMutationOverwrite ||
          mutationIdOf(current) != mutationIdOf(pending)) {
        throw StateError(alreadyPendingMessage);
      }
    }
    final payload = <String, Object?>{
      'version': 1,
      'schema': 1,
      ...encodeEntry(pending),
    };
    await _storage.write(key: storageKey(actorId), value: jsonEncode(payload));
  });

  Future<bool> clearEntry({
    required String actorId,
    required String mutationId,
  }) => serial(() async {
    final current = await readUnlocked(actorId);
    if (current == null) {
      return true;
    }
    if (mutationIdOf(current) != mutationId) {
      return false;
    }
    await _storage.delete(key: storageKey(actorId));
    return true;
  });

  Future<T> serial<T>(Future<T> Function() action) {
    final result = _queue.then<T>((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

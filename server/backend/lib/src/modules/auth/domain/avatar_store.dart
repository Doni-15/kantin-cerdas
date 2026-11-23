import 'dart:typed_data';

abstract interface class AvatarStore {
  Future<Uint8List?> read(String accountId);
  Future<bool> exists(String accountId);
  Future<void> write(String accountId, Uint8List jpeg, {bool replace = true});
  Future<Uint8List> importGooglePhoto(
    String accountId,
    Uri url, {
    required int maxBytes,
  });
}

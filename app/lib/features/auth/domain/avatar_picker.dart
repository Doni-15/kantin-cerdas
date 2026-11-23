import 'dart:typed_data';

class PickedAvatar {
  const PickedAvatar({
    required this.name,
    required this.bytes,
    required this.mediaType,
  });

  final String name;
  final Uint8List bytes;
  final String mediaType;
}

typedef AvatarPicker = Future<PickedAvatar?> Function();

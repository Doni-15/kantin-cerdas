import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/core/errors/owner_errors.dart';
import 'package:kantin_cerdas_backend/src/core/media/avatar_image.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';

class OwnerMediaService {
  OwnerMediaService({required this.store, required this.mediaStore});

  final OwnerStore store;
  final OwnerMediaStore mediaStore;
  var _activeImageWorkers = 0;

  Future<Uint8List?> readStallPhoto(String ownerId) async {
    final stall = await _requireStall(ownerId);
    if (stall['has_photo'] != true) return null;
    final stallId = stall['id'] as String;
    return mediaStore.read('stalls/$stallId/cover.jpg');
  }

  Future<Uint8List> uploadStallPhoto(
    String ownerId, {
    required Uint8List bytes,
    required String mediaType,
  }) async {
    final stall = await _requireStall(ownerId);
    final stallId = stall['id'] as String;
    final normalized = await _normalizeImage(bytes, mediaType);
    final path = 'stalls/$stallId/cover.jpg';
    await mediaStore.write(path, normalized);
    await store.setStallPhoto(ownerId, photoPath: path);
    return normalized;
  }

  Future<Map<String, Object?>> removeStallPhoto(String ownerId) async {
    final stall = await _requireStall(ownerId);
    final stallId = stall['id'] as String;
    final updated = await store.setStallPhoto(ownerId, photoPath: null);
    if (stall['has_photo'] == true) {
      await mediaStore.delete('stalls/$stallId/cover.jpg');
    }
    return updated;
  }

  Future<Uint8List?> readMenuPhoto(
    String ownerId, {
    required String menuId,
  }) async {
    final menu = await _requireMenu(ownerId, menuId);
    if (menu['has_photo'] != true) return null;
    return mediaStore.read('menus/$menuId/photo.jpg');
  }

  Future<Uint8List> uploadMenuPhoto(
    String ownerId, {
    required String menuId,
    required Uint8List bytes,
    required String mediaType,
  }) async {
    await _requireMenu(ownerId, menuId);
    final normalized = await _normalizeImage(bytes, mediaType);
    final path = 'menus/$menuId/photo.jpg';
    await mediaStore.write(path, normalized);
    await store.setMenuPhoto(ownerId, menuId: menuId, photoPath: path);
    return normalized;
  }

  Future<Map<String, Object?>> removeMenuPhoto(
    String ownerId, {
    required String menuId,
  }) async {
    final menu = await _requireMenu(ownerId, menuId);
    final updated = await store.setMenuPhoto(
      ownerId,
      menuId: menuId,
      photoPath: null,
    );
    if (menu['has_photo'] == true) {
      await mediaStore.delete('menus/$menuId/photo.jpg');
    }
    return updated;
  }

  Future<Map<dynamic, dynamic>> _requireStall(String ownerId) async {
    final payload = await store.getStall(ownerId);
    final stall = payload['stall'];
    if (stall is! Map) {
      throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    }
    return stall;
  }

  Future<Map<String, Object?>> _requireMenu(
    String ownerId,
    String menuId,
  ) async {
    final menus = await store.listMenus(ownerId, query: '');
    final menu = menus.where((item) => item['id'] == menuId).firstOrNull;
    if (menu == null) {
      throw const OwnerFailure(OwnerFailureCode.menuNotFound);
    }
    return menu;
  }

  Future<Uint8List> _normalizeImage(Uint8List bytes, String mediaType) async {
    if (_activeImageWorkers >= 2) {
      throw const OwnerFailure(OwnerFailureCode.unavailable);
    }
    _activeImageWorkers++;
    try {
      final jpeg = await normalizeAvatar(bytes, mediaType);
      if (jpeg == null) {
        throw const OwnerFailure(OwnerFailureCode.invalidImage);
      }
      return jpeg;
    } finally {
      _activeImageWorkers--;
    }
  }
}

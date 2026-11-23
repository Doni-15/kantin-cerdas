import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';

final ownerMenuControllerProvider = Provider<OwnerMenuController>(
  OwnerMenuController.new,
);

class OwnerMenuController {
  OwnerMenuController(this._ref);

  final Ref _ref;
  var _busy = false;

  Future<OwnerCategory> createCategory({
    required String accountId,
    required String name,
  }) => _guard(() async {
    final created = await _ref
        .read(ownerRepositoryProvider)
        .createCategory(_session(accountId), name: name);
    _ref.invalidate(ownerCategoriesProvider(accountId));
    return created;
  });

  Future<OwnerCategory> renameCategory({
    required String accountId,
    required String categoryId,
    required String name,
  }) => _guard(() async {
    final renamed = await _ref
        .read(ownerRepositoryProvider)
        .renameCategory(
          _session(accountId),
          categoryId: categoryId,
          name: name,
        );
    _invalidateMenusAndCategories(accountId);
    return renamed;
  });

  Future<void> deleteCategory({
    required String accountId,
    required String categoryId,
  }) => _guard(() async {
    await _ref
        .read(ownerRepositoryProvider)
        .deleteCategory(_session(accountId), categoryId: categoryId);
    _ref.invalidate(ownerCategoriesProvider(accountId));
  });

  Future<OwnerMenuItem> saveMenu({
    required String accountId,
    String? menuId,
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
    PickedOwnerPhoto? newPhoto,
    bool removePhoto = false,
  }) => _guard(() async {
    final session = _session(accountId);
    final repo = _ref.read(ownerRepositoryProvider);
    var saved = menuId == null
        ? await repo.createMenu(
            session,
            name: name,
            categoryId: categoryId,
            price: price,
            isAvailable: isAvailable,
            description: description,
          )
        : await repo.updateMenu(
            session,
            menuId: menuId,
            name: name,
            categoryId: categoryId,
            price: price,
            isAvailable: isAvailable,
            description: description,
          );
    if (newPhoto != null) {
      await repo.uploadMenuPhoto(
        session,
        menuId: saved.id,
        bytes: newPhoto.bytes,
        mediaType: newPhoto.mediaType,
      );
      _ref.invalidate(
        ownerMenuPhotoProvider((accountId: accountId, menuId: saved.id)),
      );
    } else if (removePhoto && saved.hasPhoto) {
      saved = await repo.removeMenuPhoto(session, menuId: saved.id);
      _ref.invalidate(
        ownerMenuPhotoProvider((accountId: accountId, menuId: saved.id)),
      );
    }
    _invalidateMenusAndCategories(accountId);
    return saved;
  });

  Future<OwnerMenuItem> setAvailability({
    required String accountId,
    required String menuId,
    required bool isAvailable,
  }) => _guard(() async {
    final updated = await _ref
        .read(ownerRepositoryProvider)
        .setMenuAvailability(
          _session(accountId),
          menuId: menuId,
          isAvailable: isAvailable,
        );
    _invalidateMenusAndCategories(accountId);
    return updated;
  });

  Future<OwnerMenuItem> archiveMenu({
    required String accountId,
    required String menuId,
  }) => _guard(() async {
    final updated = await _ref
        .read(ownerRepositoryProvider)
        .archiveMenu(_session(accountId), menuId: menuId);
    _invalidateMenusAndCategories(accountId);
    return updated;
  });

  Future<OwnerMenuItem> restoreMenu({
    required String accountId,
    required String menuId,
  }) => _guard(() async {
    final updated = await _ref
        .read(ownerRepositoryProvider)
        .restoreMenu(_session(accountId), menuId: menuId);
    _invalidateMenusAndCategories(accountId);
    return updated;
  });

  void _invalidateMenusAndCategories(String accountId) {
    _ref.invalidate(ownerMenusProvider);
    _ref.invalidate(ownerCategoriesProvider(accountId));
    _ref.invalidate(ownerStallProvider(accountId));
    _ref.invalidate(ownerDashboardProvider(accountId));
  }

  AuthSession _session(String accountId) => requireAccountSession(
    _ref.read(authControllerProvider).asData?.value,
    accountId,
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (_busy) {
      throw const AuthException(
        'OWNER_REQUEST_BUSY',
        'Tunggu hingga proses sebelumnya selesai.',
      );
    }
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }
}

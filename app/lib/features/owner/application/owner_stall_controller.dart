import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';

final ownerStallControllerProvider = Provider<OwnerStallController>(
  OwnerStallController.new,
);

class OwnerStallController {
  OwnerStallController(this._ref);

  final Ref _ref;
  var _busy = false;

  Future<OwnerStallBundle> saveProfile({
    required String accountId,
    required bool isNewStall,
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  }) => _guard(() async {
    final session = _session(accountId);
    final repo = _ref.read(ownerRepositoryProvider);
    final bundle = isNewStall
        ? await repo.createStall(
            session,
            name: name,
            campus: campus,
            block: block,
            description: description,
            waitMinutes: waitMinutes,
          )
        : await repo.updateStall(
            session,
            name: name,
            campus: campus,
            block: block,
            description: description,
            waitMinutes: waitMinutes,
          );
    _invalidateStallAndDashboard(accountId);
    if (isNewStall) {
      _ref.invalidate(ownerCategoriesProvider(accountId));
    }
    return bundle;
  });

  Future<OwnerStallBundle> saveSchedule({
    required String accountId,
    required List<OwnerScheduleDay> schedules,
  }) => _guard(() async {
    final bundle = await _ref
        .read(ownerRepositoryProvider)
        .updateSchedule(_session(accountId), schedules);
    _invalidateStallAndDashboard(accountId);
    return bundle;
  });

  Future<OwnerStallBundle> publishStall(String accountId) => _guard(() async {
    final bundle = await _ref
        .read(ownerRepositoryProvider)
        .publishStall(_session(accountId));
    _invalidateStallAndDashboard(accountId);
    return bundle;
  });

  Future<OwnerStallBundle> setStallOpen({
    required String accountId,
    required bool isOpen,
  }) => _guard(() async {
    final bundle = await _ref
        .read(ownerRepositoryProvider)
        .setStallOpen(_session(accountId), isOpen: isOpen);
    _invalidateStallAndDashboard(accountId);
    return bundle;
  });

  Future<void> uploadStallPhoto({
    required String accountId,
    required PickedOwnerPhoto photo,
  }) => _guard(() async {
    await _ref
        .read(ownerRepositoryProvider)
        .uploadStallPhoto(
          _session(accountId),
          bytes: photo.bytes,
          mediaType: photo.mediaType,
        );
    _ref.invalidate(ownerStallPhotoProvider(accountId));
    _invalidateStallAndDashboard(accountId);
  });

  Future<void> removeStallPhoto(String accountId) => _guard(() async {
    await _ref
        .read(ownerRepositoryProvider)
        .removeStallPhoto(_session(accountId));
    _ref.invalidate(ownerStallPhotoProvider(accountId));
    _invalidateStallAndDashboard(accountId);
  });

  void _invalidateStallAndDashboard(String accountId) {
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

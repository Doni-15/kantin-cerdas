import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/auth_failure.dart';
import 'package:kantin_cerdas/core/session/auth_usecases.dart';
import 'package:kantin_cerdas/core/session/session_user.dart';
import 'package:kantin_cerdas/core/session/user_role.dart';

extension ActiveSessionUserX on AsyncValue<User?> {
  User? get activeCustomerUser {
    if (isLoading || hasError) {
      return null;
    }
    final user = asData?.value;
    if (user == null || !user.isActive || !user.role.canUseCustomerFeatures) {
      return null;
    }
    return user;
  }

  String? get activeCustomerId => activeCustomerUser?.id;

  User? get activeOwnerUser {
    if (isLoading || hasError) {
      return null;
    }
    final user = asData?.value;
    if (user == null || !user.isActive || user.role != UserRole.owner) {
      return null;
    }
    return user;
  }

  String? get activeOwnerId => activeOwnerUser?.id;

  User? get activeAdminUser {
    if (isLoading || hasError) {
      return null;
    }
    final user = asData?.value;
    if (user == null || !user.isActive || user.role != UserRole.admin) {
      return null;
    }
    return user;
  }

  String? get activeAdminId => activeAdminUser?.id;
}

final authStateProvider =
    NotifierProvider<AuthStateNotifier, AsyncValue<User?>>(
      AuthStateNotifier.new,
    );

class AuthStateNotifier extends Notifier<AsyncValue<User?>> {
  int _generation = 0;
  bool _mutating = false;
  bool _loggingOut = false;
  bool _pendingDisabledInvalidation = false;
  String? _expectedRestoreActor;
  int get sessionGeneration => _generation;

  @override
  AsyncValue<User?> build() {
    final restore = ref.watch(restoreSessionUseCaseProvider);
    final generation = ++_generation;
    _mutating = false;
    _loggingOut = false;
    _pendingDisabledInvalidation = false;
    _expectedRestoreActor = null;
    scheduleMicrotask(() {
      if (_current(generation)) {
        unawaited(_restore(generation, restore.execute));
      }
    });
    return const AsyncLoading<User?>();
  }

  bool _current(int generation) => ref.mounted && generation == _generation;

  Future<void> _restore(
    int generation,
    Future<User?> Function() action, {
    String? expectedActor,
  }) async {
    try {
      final user = await action();
      if (!_current(generation)) {
        return;
      }
      if (user != null && !user.isActive) {
        throw const AuthAccountDisabledFailure();
      }
      if (user != null &&
          (user.id.trim().isEmpty ||
              (expectedActor != null && user.id != expectedActor))) {
        throw const AuthUnexpectedFailure();
      }
      state = AsyncData<User?>(user);
    } catch (error, stackTrace) {
      if (_current(generation)) state = AsyncError<User?>(error, stackTrace);
    }
  }

  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    if (_mutating) throw const AuthOperationInProgressFailure();
    final useCase = ref.read(loginUseCaseProvider);
    _expectedRestoreActor = null;
    _pendingDisabledInvalidation = false;
    final generation = ++_generation;
    _mutating = true;
    state = const AsyncLoading<User?>();
    try {
      final user = await useCase.execute(
        identifier: identifier,
        password: password,
      );
      if (!_current(generation)) throw const AuthOperationSupersededFailure();
      state = AsyncData<User?>(user);
      return user;
    } catch (error, stackTrace) {
      if (_current(generation)) state = AsyncError<User?>(error, stackTrace);
      rethrow;
    } finally {
      if (_current(generation)) _mutating = false;
    }
  }

  Future<void> logout() async {
    if (_loggingOut) throw const AuthOperationInProgressFailure();
    final useCase = ref.read(logoutUseCaseProvider);
    _expectedRestoreActor = null;
    _pendingDisabledInvalidation = false;
    final generation = ++_generation;
    _mutating = true;
    _loggingOut = true;
    state = const AsyncLoading<User?>();
    try {
      await useCase.execute();
      if (!_current(generation)) throw const AuthOperationSupersededFailure();
      state = const AsyncData<User?>(null);
    } catch (error, stackTrace) {
      if (_current(generation)) state = AsyncError<User?>(error, stackTrace);
      rethrow;
    } finally {
      if (_current(generation)) {
        _mutating = false;
        _loggingOut = false;
      }
    }
  }

  /// Dipanggil ketika interceptor atau fitur mendeteksi sesi berakhir (401)
  /// atau akun dinonaktifkan (403) di tengah sesi aktif.
  Future<void> invalidateSession({
    bool accountDisabled = false,
    int? expectedGeneration,
  }) async {
    if (!ref.mounted) {
      return;
    }
    if (expectedGeneration != null && expectedGeneration != _generation) {
      return;
    }
    if (_loggingOut) {
      if (accountDisabled) {
        _pendingDisabledInvalidation = true;
      }
      return;
    }
    if (!accountDisabled &&
        !_mutating &&
        !state.isLoading &&
        !state.hasError &&
        state.asData?.value == null) {
      return;
    }
    final useCase = ref.read(logoutUseCaseProvider);
    _expectedRestoreActor = null;
    _pendingDisabledInvalidation = accountDisabled;
    final generation = ++_generation;
    _mutating = true;
    _loggingOut = true;
    try {
      await useCase.execute();
    } catch (_) {
      // Sesi lokal tetap dianggap berakhir meskipun pencabutan gagal.
    } finally {
      if (_current(generation)) {
        final disabled = _pendingDisabledInvalidation;
        _pendingDisabledInvalidation = false;
        _mutating = false;
        _loggingOut = false;
        state = disabled
            ? AsyncError<User?>(
                const AuthAccountDisabledFailure(),
                StackTrace.current,
              )
            : const AsyncData<User?>(null);
      }
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_mutating) throw const AuthOperationInProgressFailure();
    final user = state.asData?.value;
    if (state.isLoading || state.hasError || user == null || !user.isActive) {
      throw const AuthSessionExpiredFailure();
    }
    final useCase = ref.read(changePasswordUseCaseProvider);
    final generation = _generation;
    _mutating = true;
    try {
      await useCase.execute(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!_current(generation)) throw const AuthOperationSupersededFailure();
    } catch (error, stackTrace) {
      if (_current(generation) &&
          (error is AuthSessionExpiredFailure ||
              error is AuthAccountDisabledFailure ||
              error is AuthStorageFailure)) {
        state = AsyncError<User?>(error, stackTrace);
      }
      rethrow;
    } finally {
      if (_current(generation)) _mutating = false;
    }
  }

  Future<User> updateProfileAvatar({required String? avatarUrl}) async {
    if (_mutating) throw const AuthOperationInProgressFailure();
    final currentUser = state.asData?.value;
    if (state.isLoading ||
        state.hasError ||
        currentUser == null ||
        !currentUser.isActive) {
      throw const AuthSessionExpiredFailure();
    }
    final useCase = ref.read(updateProfileAvatarUseCaseProvider);
    final generation = _generation;
    _mutating = true;
    try {
      final updatedUser = await useCase.execute(avatarUrl: avatarUrl);
      if (!_current(generation)) throw const AuthOperationSupersededFailure();
      if (!updatedUser.isActive) {
        throw const AuthAccountDisabledFailure();
      }
      if (updatedUser.id != currentUser.id ||
          updatedUser.role != currentUser.role) {
        throw const AuthUnexpectedFailure();
      }
      state = AsyncData<User?>(updatedUser);
      return updatedUser;
    } catch (error, stackTrace) {
      if (_current(generation) &&
          (error is AuthSessionExpiredFailure ||
              error is AuthAccountDisabledFailure ||
              error is AuthStorageFailure)) {
        state = AsyncError<User?>(error, stackTrace);
      }
      rethrow;
    } finally {
      if (_current(generation)) _mutating = false;
    }
  }

  bool refreshSession() {
    if (!ref.mounted || _mutating || state.isLoading || state.hasError) {
      return false;
    }
    final user = state.asData?.value;
    if (user == null || !user.isActive) {
      return false;
    }
    _expectedRestoreActor = user.id;
    final restore = ref.read(restoreSessionUseCaseProvider);
    final generation = ++_generation;
    state = const AsyncLoading<User?>();
    unawaited(_restore(generation, restore.execute, expectedActor: user.id));
    return true;
  }

  void retryRestore() {
    if (!ref.mounted || _mutating || state.isLoading) return;
    final restore = ref.read(restoreSessionUseCaseProvider);
    final generation = ++_generation;
    state = const AsyncLoading<User?>();
    unawaited(
      _restore(
        generation,
        restore.execute,
        expectedActor: _expectedRestoreActor,
      ),
    );
  }
}

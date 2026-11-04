import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/session/auth_failure.dart';
import 'package:kantin_cerdas/core/session/auth_repository.dart';
import 'package:kantin_cerdas/core/session/auth_validator.dart';
import 'package:kantin_cerdas/core/session/session_user.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> execute({
    required String identifier,
    required String password,
  }) async {
    final normalizedIdentifier = identifier.trim();
    final errors = <String, String>{};

    final identifierIssue = AuthValidator.identifier(normalizedIdentifier);

    if (identifierIssue != null) {
      errors['identifier'] = identifierIssue.name;
    }

    final passwordIssue = AuthValidator.loginPassword(password);

    if (passwordIssue != null) {
      errors['password'] = passwordIssue.name;
    }

    if (errors.isNotEmpty) {
      throw AuthValidationFailure(errors);
    }

    return _repository.login(
      identifier: normalizedIdentifier,
      password: password,
    );
  }
}

class RegisterUseCase {
  const RegisterUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> execute({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim();
    final errors = <String, String>{};
    final nameIssue = AuthValidator.name(normalizedName);

    if (nameIssue != null) {
      errors['name'] = nameIssue.name;
    }

    final usernameIssue = AuthValidator.username(normalizedUsername);

    if (usernameIssue != null) {
      errors['username'] = usernameIssue.name;
    }

    final emailIssue = AuthValidator.email(normalizedEmail);

    if (emailIssue != null) {
      errors['email'] = emailIssue.name;
    }

    final passwordIssue = AuthValidator.password(password);

    if (passwordIssue != null) {
      errors['password'] = passwordIssue.name;
    }

    if (errors.isNotEmpty) {
      throw AuthValidationFailure(errors);
    }

    return _repository.register(
      name: normalizedName,
      username: normalizedUsername,
      email: normalizedEmail,
      password: password,
    );
  }
}

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);
  final AuthRepository _repository;

  Future<User?> execute() {
    return _repository.restoreSession();
  }
}

class LogoutUseCase {
  const LogoutUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> execute() {
    return _repository.logout();
  }
}

class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> execute({required String email}) {
    final normalized = email.trim();
    final issue = AuthValidator.passwordResetEmail(normalized);
    if (issue != null) {
      throw AuthValidationFailure({'email': issue.name});
    }
    return _repository.requestPasswordReset(email: normalized);
  }
}

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> execute({
    required String currentPassword,
    required String newPassword,
  }) async {
    final errors = <String, String>{};

    final currentPasswordIssue = AuthValidator.loginPassword(currentPassword);

    if (currentPasswordIssue != null) {
      errors['current_password'] = currentPasswordIssue.name;
    }

    final newPasswordIssue = AuthValidator.newPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (newPasswordIssue != null) {
      errors['new_password'] = newPasswordIssue.name;
    }

    if (errors.isNotEmpty) {
      throw AuthValidationFailure(errors);
    }

    await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordResetUseCase>((ref) {
      return RequestPasswordResetUseCase(ref.watch(authRepositoryProvider));
    });

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(authRepositoryProvider));
});

class UpdateProfileAvatarUseCase {
  const UpdateProfileAvatarUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> execute({required String? avatarUrl}) {
    final String? safeUrl;
    try {
      safeUrl = ImageSecurityValidator.normalizeSafeImageUrl(
        avatarUrl,
        fieldName: 'avatar_url',
      );
    } on FormatException {
      throw AuthValidationFailure(const {'avatar_url': 'invalid'});
    }
    return _repository.updateProfileAvatar(avatarUrl: safeUrl);
  }
}

final updateProfileAvatarUseCaseProvider = Provider<UpdateProfileAvatarUseCase>(
  (ref) {
    return UpdateProfileAvatarUseCase(ref.watch(authRepositoryProvider));
  },
);

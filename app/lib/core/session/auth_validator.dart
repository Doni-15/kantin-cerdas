import 'package:characters/characters.dart';

enum AuthValidationIssue {
  required,
  tooLong,
  invalidEmail,
  invalidUsername,
  invalidUsernameLength,
  passwordTooShort,
  passwordTooLong,
  passwordUnchanged,
  passwordMismatch,
}

abstract final class AuthValidator {
  static const minUsernameLength = 6;
  static const maxUsernameLength = 20;
  static const minPasswordLength = 6;
  static const maxPasswordLength = 128;
  static const maxNameLength = 120;
  static const maxIdentifierLength = 254;
  static const maxEmailLength = 254;
  static const maxPasswordResetEmailLength = 254;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_.]+$');

  static AuthValidationIssue? identifier(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AuthValidationIssue.required;
    }
    if (trimmed.characters.length > maxIdentifierLength) {
      return AuthValidationIssue.tooLong;
    }
    return null;
  }

  static AuthValidationIssue? name(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AuthValidationIssue.required;
    }
    if (trimmed.characters.length > maxNameLength) {
      return AuthValidationIssue.tooLong;
    }
    return null;
  }

  static AuthValidationIssue? email(String value) {
    final input = value.trim();

    if (input.isEmpty) {
      return AuthValidationIssue.required;
    }

    if (input.characters.length > maxEmailLength ||
        !_emailPattern.hasMatch(input)) {
      return AuthValidationIssue.invalidEmail;
    }

    return null;
  }

  static AuthValidationIssue? passwordResetEmail(String value) {
    if (value.trim().characters.length > maxPasswordResetEmailLength) {
      return AuthValidationIssue.invalidEmail;
    }
    return email(value);
  }

  static AuthValidationIssue? username(String value) {
    final input = value.trim();

    if (input.isEmpty) {
      return AuthValidationIssue.required;
    }

    final length = input.characters.length;
    if (length < minUsernameLength || length > maxUsernameLength) {
      return AuthValidationIssue.invalidUsernameLength;
    }

    if (!_usernamePattern.hasMatch(input)) {
      return AuthValidationIssue.invalidUsername;
    }

    return null;
  }

  static AuthValidationIssue? loginPassword(String value) {
    if (value.isEmpty) {
      return AuthValidationIssue.required;
    }
    if (value.characters.length > maxPasswordLength) {
      return AuthValidationIssue.passwordTooLong;
    }
    return null;
  }

  static AuthValidationIssue? password(String value) {
    final issue = loginPassword(value);

    if (issue != null) return issue;

    if (value.characters.length < minPasswordLength) {
      return AuthValidationIssue.passwordTooShort;
    }

    return null;
  }

  static AuthValidationIssue? newPassword({
    required String currentPassword,
    required String newPassword,
  }) {
    final issue = password(newPassword);

    if (issue != null) return issue;

    if (newPassword == currentPassword) {
      return AuthValidationIssue.passwordUnchanged;
    }

    return null;
  }

  static AuthValidationIssue? confirmPassword({
    required String password,
    required String confirmation,
  }) {
    if (confirmation.isEmpty) {
      return AuthValidationIssue.required;
    }

    if (confirmation != password) {
      return AuthValidationIssue.passwordMismatch;
    }

    return null;
  }
}

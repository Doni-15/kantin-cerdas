import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterDraft {
  const RegisterDraft({
    required this.name,
    required this.email,
    required this.password,
    this.avatarPreviewBytes,
  });

  final String name;
  final String email;
  final String password;
  final Uint8List? avatarPreviewBytes;

  RegisterDraft copyWith({
    String? name,
    String? email,
    String? password,
    Uint8List? avatarPreviewBytes,
    bool clearAvatar = false,
  }) {
    return RegisterDraft(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarPreviewBytes: clearAvatar
          ? null
          : (avatarPreviewBytes ?? this.avatarPreviewBytes),
    );
  }
}

final registerDraftProvider =
    NotifierProvider.autoDispose<RegisterDraftNotifier, RegisterDraft?>(
      RegisterDraftNotifier.new,
    );

class RegisterDraftNotifier extends Notifier<RegisterDraft?> {
  @override
  RegisterDraft? build() {
    return null;
  }

  void setDraft(RegisterDraft draft) {
    state = draft;
  }

  void updateAvatar(Uint8List? avatarPreviewBytes) {
    final current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(
      avatarPreviewBytes: avatarPreviewBytes,
      clearAvatar: avatarPreviewBytes == null,
    );
  }

  void clearPassword() {
    final current = state;
    if (current == null || current.password.isEmpty) {
      return;
    }
    state = current.copyWith(password: '');
  }

  void clear() {
    state = null;
  }
}

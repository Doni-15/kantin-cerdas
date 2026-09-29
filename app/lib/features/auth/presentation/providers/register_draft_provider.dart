import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data langkah 1 registrasi (nama, email, password) yang dibawa ke langkah 2.
class RegisterDraft {
  const RegisterDraft({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

final registerDraftProvider =
    NotifierProvider<RegisterDraftNotifier, RegisterDraft?>(
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

  void clear() {
    state = null;
  }
}

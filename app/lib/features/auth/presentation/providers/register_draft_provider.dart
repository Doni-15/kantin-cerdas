import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterDraft {
  const RegisterDraft({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  RegisterDraft copyWith({String? name, String? email, String? password}) {
    return RegisterDraft(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
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

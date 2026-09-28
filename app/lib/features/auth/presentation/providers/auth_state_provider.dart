import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';

final authStateProvider = NotifierProvider<AuthStateNotifier, User?>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  void setUser(User user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }
}
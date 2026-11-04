import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';

enum PasswordResetPhase { idle, submitting, acknowledged, failed }

class PasswordResetState {
  const PasswordResetState.idle()
    : phase = PasswordResetPhase.idle,
      failure = null;
  const PasswordResetState.submitting()
    : phase = PasswordResetPhase.submitting,
      failure = null;
  const PasswordResetState.acknowledged()
    : phase = PasswordResetPhase.acknowledged,
      failure = null;
  const PasswordResetState.failed(this.failure)
    : phase = PasswordResetPhase.failed;

  final PasswordResetPhase phase;
  final AuthFailure? failure;

  bool get isSubmitting => phase == PasswordResetPhase.submitting;
  bool get isAcknowledged => phase == PasswordResetPhase.acknowledged;
}

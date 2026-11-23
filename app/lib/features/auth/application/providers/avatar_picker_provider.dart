import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/data/avatar_picker.dart';

final avatarPickerProvider = Provider<AvatarPicker>(
  (ref) => pickAvatarFromDevice,
);

import 'package:kantin_cerdas/core/config/app_feature_flags.dart';

import '../../support/simulation_harness.dart';

void main() {
  group('AppFeatureFlags', () {
    test('flag fitur tanpa endpoint backend bernilai false secara default', () {
      expect(AppFeatureFlags.enableGoogleAuth, isFalse);
      expect(AppFeatureFlags.enableProfilePhotoUpload, isTrue);
      expect(AppFeatureFlags.enableEmailVerification, isFalse);
      expect(AppFeatureFlags.enableDeviceSessionManagement, isFalse);
      expect(AppFeatureFlags.enableLoginActivityHistory, isFalse);
    });
  });
}

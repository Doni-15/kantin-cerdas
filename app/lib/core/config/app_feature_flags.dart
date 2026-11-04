/// Konfigurasi feature flag compile-time untuk fitur tambahan aplikasi.
abstract final class AppFeatureFlags {
  static const bool enableGoogleAuth = bool.fromEnvironment(
    'ENABLE_GOOGLE_AUTH',
    defaultValue: true,
  );

  static const bool enableProfilePhotoUpload = bool.fromEnvironment(
    'ENABLE_PROFILE_PHOTO_UPLOAD',
    defaultValue: true,
  );

  static const bool enableEmailVerification = bool.fromEnvironment(
    'ENABLE_EMAIL_VERIFICATION',
    defaultValue: true,
  );

  static const bool enableDeviceSessionManagement = bool.fromEnvironment(
    'ENABLE_DEVICE_SESSION_MANAGEMENT',
    defaultValue: true,
  );

  static const bool enableLoginActivityHistory = bool.fromEnvironment(
    'ENABLE_LOGIN_ACTIVITY_HISTORY',
    defaultValue: true,
  );
}

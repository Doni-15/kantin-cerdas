abstract interface class AppFailure implements Exception {
  String get code;
  String get message;
}

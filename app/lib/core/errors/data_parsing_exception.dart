final class DataParsingException implements Exception {
  const DataParsingException(this.message);
  final String message;

  @override
  String toString() {
    return 'DataParsingException: $message';
  }
}

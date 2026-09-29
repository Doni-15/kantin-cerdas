/// Response dari sumber data tidak sesuai kontrak (field hilang, nilai tidak dikenal, dll).
class DataParsingException implements Exception {
  const DataParsingException(this.message);

  final String message;

  @override
  String toString() => 'DataParsingException: $message';
}

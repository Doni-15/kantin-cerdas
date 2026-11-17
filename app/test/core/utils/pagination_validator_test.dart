import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/pagination_validator.dart';

void main() {
  group('validateCursorPageBounds', () {
    test(
      'menolak batas halaman, kursor, dan jumlah item yang tidak konsisten',
      () {
        expect(
          () => validateCursorPageBounds(
            limit: 0,
            requestCursor: null,
            itemCount: 0,
            nextCursor: null,
          ),
          throwsA(isA<DataParsingException>()),
        );
        expect(
          () => validateCursorPageBounds(
            limit: 1,
            requestCursor: 'cur-1',
            itemCount: 2,
            nextCursor: 'cur-2',
          ),
          throwsA(isA<DataParsingException>()),
        );
        expect(
          () => validateCursorPageBounds(
            limit: 10,
            requestCursor: 'cur-1',
            itemCount: 5,
            nextCursor: 'cur-1',
          ),
          throwsA(isA<DataParsingException>()),
        );
      },
    );
  });
}

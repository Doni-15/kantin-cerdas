import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/canteen_submissions/canteen_submissions_validator.dart';
import 'package:test/test.dart';

void main() {
  const validSubmissionId = '0123456789abcdef0123456789abcdef0123456789abcdef';

  group('CanteenSubmissionsValidator.validateSubmit', () {
    test(
      'menerima pengajuan perdana yang valid tanpa previous_id/previous_version',
      () {
        final input = CanteenSubmissionsValidator.validateSubmit(
          <String, Object?>{
            'submission_id': validSubmissionId,
            'name': '  Kantin Nusantara  ',
            'description': '  Menyediakan nasi goreng dan lauk sehat kampus. ',
            'location': ' Blok A No. 3 ',
            'phone': ' 0812-3456-7890 ',
            'previous_id': null,
            'previous_version': null,
          },
          idempotencyKeyHeader: validSubmissionId,
        );

        expect(input.submissionId, validSubmissionId);
        expect(input.name, 'Kantin Nusantara');
        expect(
          input.description,
          'Menyediakan nasi goreng dan lauk sehat kampus.',
        );
        expect(input.location, 'Blok A No. 3');
        expect(input.phone, '0812-3456-7890');
        expect(input.previousId, isNull);
        expect(input.previousVersion, isNull);
      },
    );

    test(
      'menerima pengajuan ulang dengan pasangan previous_id dan previous_version valid',
      () {
        final input = CanteenSubmissionsValidator.validateSubmit(
          <String, Object?>{
            'submission_id': validSubmissionId,
            'name': 'Kantin Nusantara Baru',
            'description': 'Menu sehat mahasiswa dengan harga terjangkau.',
            'location': 'Blok B No. 2',
            'phone': '+62 812 3456 7890',
            'previous_id': 'app_0123456789abcdef0123456789abcdef',
            'previous_version': 2,
          },
          idempotencyKeyHeader: validSubmissionId,
        );

        expect(input.previousId, 'app_0123456789abcdef0123456789abcdef');
        expect(input.previousVersion, 2);
      },
    );

    test('menolak jika header Idempotency-Key dan submission_id berbeda', () {
      expect(
        () => CanteenSubmissionsValidator.validateSubmit(
          <String, Object?>{
            'submission_id':
                'abcdef0123456789abcdef0123456789abcdef0123456789',
            'name': 'Kantin Nusantara',
            'description': 'Deskripsi usaha',
            'location': 'Blok A',
            'phone': '081234567890',
          },
          idempotencyKeyHeader: validSubmissionId,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.code, 'code', 'INVALID_INPUT'),
        ),
      );
    });

    test(
      'menolak jika hanya salah satu dari previous_id atau previous_version yang diisi',
      () {
        expect(
          () => CanteenSubmissionsValidator.validateSubmit(
            <String, Object?>{
              'submission_id': validSubmissionId,
              'name': 'Kantin Nusantara',
              'description': 'Deskripsi usaha',
              'location': 'Blok A',
              'phone': '081234567890',
              'previous_id': 'app_0123456789abcdef0123456789abcdef',
              'previous_version': null,
            },
            idempotencyKeyHeader: validSubmissionId,
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 422)
                .having(
                  (e) => e.fieldErrors?.containsKey('previous_id'),
                  'has previous_id error',
                  isTrue,
                ),
          ),
        );
      },
    );

    test(
      'menolak format nomor telepon yang kurang dari 8 digit atau mengandung huruf',
      () {
        expect(
          () => CanteenSubmissionsValidator.validateSubmit(
            <String, Object?>{
              'submission_id': validSubmissionId,
              'name': 'Kantin Nusantara',
              'description': 'Deskripsi usaha',
              'location': 'Blok A',
              'phone': '0812abc',
            },
            idempotencyKeyHeader: validSubmissionId,
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 422)
                .having(
                  (e) => e.fieldErrors?.containsKey('phone'),
                  'has phone error',
                  isTrue,
                ),
          ),
        );
      },
    );
  });
}

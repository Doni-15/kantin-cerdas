import 'package:characters/characters.dart';

import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/canteen_submissions/canteen_submissions_validated_input.dart';

export 'package:kantin_cerdas_backend/src/modules/customer/canteen_submissions/canteen_submissions_validated_input.dart';

/// Validator Zero-Trust untuk modul Pengajuan Kantin (`/v1/customer/canteen-applications`).
final class CanteenSubmissionsValidator {
  const CanteenSubmissionsValidator._();

  static const int _maxNameGraphemes = 120;
  static const int _maxNameCodePoints = 480;
  static const int _maxDescriptionGraphemes = 1000;
  static const int _maxDescriptionCodePoints = 4000;
  static const int _maxLocationGraphemes = 120;
  static const int _maxLocationCodePoints = 480;
  static const int _maxPhoneLength = 24;
  static const int _minPhoneDigits = 8;
  static const int _maxPhoneDigits = 15;

  static final RegExp _applicationIdPattern = RegExp(r'^app_[a-f0-9]{32}$');
  static final RegExp _phoneAllowedPattern = RegExp(r'^\+?[0-9 ()-]+$');
  static final RegExp _nonDigitPattern = RegExp(r'[^0-9]');

  static ValidatedSubmitCanteenApplicationInput validateSubmit(
    Map<String, Object?> body, {
    String? idempotencyKeyHeader,
  }) {
    final rawHeader = (idempotencyKeyHeader ?? '').trim();
    final rawBodyId = body['submission_id'] ?? body['submissionId'];
    if (rawBodyId != null && rawBodyId is! String) {
      throw ApiException.unprocessable(
        'Field submission_id harus berupa teks.',
        code: 'INVALID_INPUT',
        fieldErrors: const <String, String>{
          'submission_id': 'Harus berupa teks.',
        },
      );
    }
    final bodyId = (rawBodyId is String ? rawBodyId : '').trim();

    if (rawHeader.isNotEmpty && bodyId.isNotEmpty && rawHeader != bodyId) {
      throw ApiException.unprocessable(
        'Header Idempotency-Key dan field submission_id harus identik.',
        code: 'INVALID_INPUT',
        fieldErrors: const <String, String>{
          'submission_id': 'Harus sama dengan header Idempotency-Key.',
        },
      );
    }

    final submissionId = rawHeader.isNotEmpty ? rawHeader : bodyId;
    if (!SecurityConstants.idempotencyKeyPattern.hasMatch(submissionId)) {
      throw ApiException.unprocessable(
        'Idempotency-Key (submission_id) wajib berupa 48 karakter hex huruf kecil.',
        code: 'INVALID_INPUT',
        fieldErrors: const <String, String>{
          'submission_id': 'Wajib berupa 48 karakter hex huruf kecil.',
        },
      );
    }

    final fieldErrors = <String, String>{};

    final rawName = body['name'];
    final name = (rawName is String ? rawName : '').trim();
    if (name.isEmpty ||
        name.characters.length > _maxNameGraphemes ||
        name.length > _maxNameCodePoints) {
      fieldErrors['name'] = 'Nama stan wajib antara 1 dan 120 karakter.';
    }

    final rawDesc = body['description'];
    final description = (rawDesc is String ? rawDesc : '').trim();
    if (description.isEmpty ||
        description.characters.length > _maxDescriptionGraphemes ||
        description.length > _maxDescriptionCodePoints) {
      fieldErrors['description'] =
          'Deskripsi pengajuan wajib antara 1 dan 1000 karakter.';
    }

    final rawLoc = body['location'];
    final location = (rawLoc is String ? rawLoc : '').trim();
    if (location.isEmpty ||
        location.characters.length > _maxLocationGraphemes ||
        location.length > _maxLocationCodePoints) {
      fieldErrors['location'] = 'Lokasi stan wajib antara 1 dan 120 karakter.';
    }

    final rawPhone = body['phone'];
    final phone = (rawPhone is String ? rawPhone : '').trim();
    final digits = phone.replaceAll(_nonDigitPattern, '');
    if (phone.isEmpty ||
        phone.length > _maxPhoneLength ||
        !_phoneAllowedPattern.hasMatch(phone) ||
        digits.length < _minPhoneDigits ||
        digits.length > _maxPhoneDigits) {
      fieldErrors['phone'] =
          'Format nomor telepon tidak valid (8-15 digit, maksimal 24 karakter).';
    }

    final rawPrevId = body['previous_id'] ?? body['previousId'];
    String? previousId;
    if (rawPrevId != null) {
      if (rawPrevId is! String) {
        fieldErrors['previous_id'] = 'Field previous_id harus berupa teks.';
      } else {
        final trimmedPrev = rawPrevId.trim();
        if (trimmedPrev.isNotEmpty) {
          if (!_applicationIdPattern.hasMatch(trimmedPrev)) {
            fieldErrors['previous_id'] =
                'Format previous_id wajib berupa app_ diikuti 32 karakter hex.';
          } else {
            previousId = trimmedPrev;
          }
        }
      }
    }

    final rawPrevVersion =
        body['previous_version'] ?? body['previousVersion'];
    int? previousVersion;
    if (rawPrevVersion != null) {
      if (rawPrevVersion is! int || rawPrevVersion < 1) {
        fieldErrors['previous_version'] =
            'Field previous_version harus berupa bilangan bulat >= 1.';
      } else {
        previousVersion = rawPrevVersion;
      }
    }

    if ((previousId == null) != (previousVersion == null)) {
      fieldErrors['previous_id'] =
          'Parameter previous_id dan previous_version harus keduanya diisi atau keduanya kosong.';
    }

    if (fieldErrors.isNotEmpty) {
      throw ApiException.unprocessable(
        fieldErrors.values.first,
        code: 'INVALID_INPUT',
        fieldErrors: fieldErrors,
      );
    }

    return ValidatedSubmitCanteenApplicationInput(
      submissionId: submissionId,
      name: name,
      description: description,
      location: location,
      phone: phone,
      previousId: previousId,
      previousVersion: previousVersion,
    );
  }
}

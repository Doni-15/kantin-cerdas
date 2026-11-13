import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/media/image_picker_port.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/media/media_upload_repository.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_profile_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_stall_settings_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/menu/owner_menu_editor.dart';

import '../../support/image_fixtures.dart';
import '../../support/simulation/simulation.dart';
import '../../support/simulation/simulation_overrides.dart';

class ConfigurablePickerPort implements ImagePickerPort {
  ConfigurablePickerPort(this.bytesToReturn);

  Uint8List? bytesToReturn;
  ImagePickSource? lastSource;

  @override
  Future<RawPickedImage?> pickImage(ImagePickSource source) async {
    lastSource = source;
    final bytes = bytesToReturn;
    return bytes == null ? null : RawPickedImage(bytes: bytes);
  }
}

class RecordingUploadRepository implements MediaUploadRepository {
  final List<ValidatedUploadImage> uploadedImages = <ValidatedUploadImage>[];

  @override
  bool get isConfigured => true;

  @override
  Future<String> uploadImage(ValidatedUploadImage image) async {
    uploadedImages.add(image);
    return 'https://cdn.kantincerdas.ac.id/uploads/${image.category.slug}/${image.safeFileName}';
  }
}

void main() {
  group('Alur widget unggah foto: avatar profil, foto menu, dan foto stan', () {
    testWidgets(
      'CustomerProfilePage dapat memilih foto profil (Kamera/Galeri), memvalidasi & mengunggah dengan nama acak, lalu menghapus foto profil',
      (tester) async {
        final store = SimulationStore.memory();
        await store.signIn('customer-1');
        final picker = ConfigurablePickerPort(
          SimulationImagePickerPort.validSamplePngBytes,
        );
        final uploader = RecordingUploadRepository();

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
        final picker = ConfigurablePickerPort(maliciousPolyglot);
        final uploader = RecordingUploadRepository();

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
        picker.bytesToReturn = validJpegBytes();
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
  });
}

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Pilihan aksi dari bottom sheet sumber gambar.
sealed class KcImageSheetResult {
  const KcImageSheetResult();
}

final class KcImagePickSourceSelected extends KcImageSheetResult {
  const KcImagePickSourceSelected(this.source);
  final ImagePickSource source;
}

final class KcImageRemoveSelected extends KcImageSheetResult {
  const KcImageRemoveSelected();
}

/// Menampilkan bottom sheet bergaya WhatsApp untuk memilih sumber gambar
/// (**Kamera**, **Galeri**) atau **Hapus foto** jika gambar sudah terpasang.
Future<KcImageSheetResult?> showKcImageSourceSheet({
  required BuildContext context,
  required String title,
  bool canRemove = false,
  String removeLabel = 'Hapus foto',
}) {
  return showModalBottomSheet<KcImageSheetResult>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colors = theme.colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          KcSpacing.md,
          0,
          KcSpacing.md,
          KcSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KcSpacing.md,
                vertical: KcSpacing.xs,
              ),
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            ListTile(
              key: const Key('kc_image_source_camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil foto (Kamera)'),
              onTap: () => Navigator.pop(
                sheetContext,
                const KcImagePickSourceSelected(ImagePickSource.camera),
              ),
            ),
            ListTile(
              key: const Key('kc_image_source_gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(
                sheetContext,
                const KcImagePickSourceSelected(ImagePickSource.gallery),
              ),
            ),
            if (canRemove)
              ListTile(
                key: const Key('kc_image_source_remove'),
                leading: Icon(Icons.delete_outline, color: colors.error),
                title: Text(removeLabel, style: TextStyle(color: colors.error)),
                onTap: () =>
                    Navigator.pop(sheetContext, const KcImageRemoveSelected()),
              ),
          ],
        ),
      );
    },
  );
}

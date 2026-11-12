import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/media/image_picker_port.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/media/media_upload_failure.dart';
import 'package:kantin_cerdas/core/media/media_upload_repository.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';
import 'package:kantin_cerdas/core/widgets/kc_image_source_sheet.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Field pemilihan, validasi keamanan, dan pengunggahan gambar yang dapat
/// digunakan kembali pada form (mis. foto menu makanan dan foto stan kantin).
class KcImagePickerField extends ConsumerStatefulWidget {
  const KcImagePickerField({
    super.key,
    required this.label,
    required this.actorId,
    required this.category,
    required this.imageUrl,
    required this.enabled,
    required this.onChanged,
    this.fallbackIcon = Icons.image_outlined,
    this.onBusyChanged,
  });

  final String label;
  final String actorId;
  final MediaUploadCategory category;
  final String? imageUrl;
  final bool enabled;
  final IconData fallbackIcon;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool>? onBusyChanged;

  @override
  ConsumerState<KcImagePickerField> createState() => _KcImagePickerFieldState();
}

class _KcImagePickerFieldState extends ConsumerState<KcImagePickerField> {
  bool _uploading = false;
  String? _errorMessage;
  Uint8List? _localPreviewBytes;
  String? _localPreviewForUrl;

  void _setUploading(bool value) {
    if (_uploading == value) {
      return;
    }
    setState(() => _uploading = value);
    widget.onBusyChanged?.call(value);
  }

  Future<void> _openPickerSheet() async {
    if (!widget.enabled || _uploading) {
      return;
    }
    final hasImage =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;
    final choice = await showKcImageSourceSheet(
      context: context,
      title: widget.label,
      canRemove: hasImage,
      removeLabel: 'Hapus foto',
    );
    if (!mounted || choice == null || !widget.enabled || _uploading) {
      return;
    }

    switch (choice) {
      case KcImageRemoveSelected():
        setState(() {
          _errorMessage = null;
          _localPreviewBytes = null;
          _localPreviewForUrl = null;
        });
        widget.onChanged(null);
      case KcImagePickSourceSelected(:final source):
        await _pickValidateAndUpload(source);
    }
  }

  Future<void> _pickValidateAndUpload(ImagePickSource source) async {
    _setUploading(true);
    setState(() => _errorMessage = null);

    try {
      final picker = ref.read(imagePickerPortProvider);
      final raw = await picker.pickImage(source);
      if (!mounted) {
        return;
      }
      if (raw == null) {
        return;
      }

      // Validasi Zero-Trust: Magic Bytes, batas 2 MB, anti-polyglot/script,
      // serta pembuatan nama file acak `{actorId}_{category}_{uuid}.{ext}`.
      final validated = ImageSecurityValidator.validateAndPrepare(
        bytes: raw.bytes,
        actorId: widget.actorId,
        category: widget.category,
      );

      final uploadRepo = ref.read(mediaUploadRepositoryProvider);
      final uploadedUrl = await uploadRepo.uploadImage(validated);
      if (!mounted) {
        return;
      }

      setState(() {
        _localPreviewBytes = validated.bytes;
        _localPreviewForUrl = uploadedUrl;
        _errorMessage = null;
      });
      widget.onChanged(uploadedUrl);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = mediaUploadErrorMessage(error);
      });
    } finally {
      if (mounted) {
        _setUploading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasImage =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;
    final previewBytes = (hasImage && widget.imageUrl == _localPreviewForUrl)
        ? _localPreviewBytes
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: theme.textTheme.labelLarge),
        const SizedBox(height: KcSpacing.xs),
        Container(
          padding: const EdgeInsets.all(KcSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(KcRadius.control),
          ),
          child: Row(
            children: [
              KcEntityImage.thumbnail(
                imageUrl: widget.imageUrl,
                previewBytes: previewBytes,
                width: 64,
                height: 64,
                fallbackIcon: widget.fallbackIcon,
              ),
              const SizedBox(width: KcSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasImage ? 'Foto terpilih' : 'Belum ada foto',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: KcSpacing.xs / 2),
                    Text(
                      'Format JPG, PNG, atau WEBP (maks. 2 MB).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: KcSpacing.sm),
                    Wrap(
                      spacing: KcSpacing.xs,
                      runSpacing: KcSpacing.xs,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('kc_image_picker_field_button'),
                          onPressed: widget.enabled && !_uploading
                              ? _openPickerSheet
                              : null,
                          icon: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 18,
                                ),
                          label: Text(
                            _uploading
                                ? 'Mengunggah...'
                                : (hasImage ? 'Ubah foto' : 'Pilih foto'),
                          ),
                        ),
                        if (hasImage && !_uploading)
                          TextButton(
                            key: const Key('kc_image_picker_field_remove'),
                            onPressed: widget.enabled
                                ? () {
                                    setState(() {
                                      _errorMessage = null;
                                      _localPreviewBytes = null;
                                      _localPreviewForUrl = null;
                                    });
                                    widget.onChanged(null);
                                  }
                                : null,
                            child: const Text('Hapus'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: KcSpacing.xs),
          Text(
            _errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}

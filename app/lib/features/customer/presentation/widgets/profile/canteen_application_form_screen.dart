import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_snackbar.dart';
import 'package:kantin_cerdas/core/widgets/kc_text_field.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/validators/canteen_application_validator.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/canteen_application_submit_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/utils/canteen_application_error_message.dart';

/// Layar formulir "Buka Kantin".
///
/// Widget ini hanya memegang state tampilan (controller teks + pesan error field).
/// Aturan validasi ada di domain, proses kirim ada di submit controller.
class CanteenApplicationFormScreen extends ConsumerStatefulWidget {
  const CanteenApplicationFormScreen({super.key});

  @override
  ConsumerState<CanteenApplicationFormScreen> createState() =>
      _CanteenApplicationFormScreenState();
}

class _CanteenApplicationFormScreenState
    extends ConsumerState<CanteenApplicationFormScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  String? _nameError;
  String? _descriptionError;
  String? _addressError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    // Cegah double-submit.
    if (ref.read(canteenApplicationSubmitProvider).isLoading) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final address = _addressController.text.trim();

    setState(() {
      _nameError = CanteenApplicationValidator.name(name);
      _descriptionError = CanteenApplicationValidator.description(description);
      _addressError = CanteenApplicationValidator.address(address);
    });

    if (_nameError != null ||
        _descriptionError != null ||
        _addressError != null) {
      KcSnackBar.error(
        context,
        'Mohon lengkapi kolom yang berwarna merah.',
      );
      return;
    }

    ref.read(canteenApplicationSubmitProvider.notifier).submit(
          name: name,
          description: description,
          address: address,
        );
  }

  void _handleSubmitError(Object error) {
    // Error milik field (422 dari server): tampilkan di bawah field-nya.
    if (error is CanteenApplicationValidationFailure) {
      final errors = error.fieldErrors;

      setState(() {
        _nameError = errors['name'];
        _descriptionError = errors['description'];
        _addressError = errors['address'];
      });

      KcSnackBar.error(
        context,
        'Mohon lengkapi kolom yang berwarna merah.',
      );
      return;
    }

    KcSnackBar.error(
      context,
      canteenApplicationErrorMessage(error),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CanteenApplication?>>(
      canteenApplicationSubmitProvider,
      (previous, next) {
        next.whenOrNull(
          data: (application) {
            if (application == null) {
              return;
            }

            // Layar akan berganti ke status pengajuan karena state
            // "pengajuan saya" sudah diperbarui oleh controller.
            KcSnackBar.success(
              context,
              'Pengajuan buka kantin berhasil dikirim.',
            );
          },
          error: (error, stackTrace) => _handleSubmitError(error),
        );
      },
    );

    final isSubmitting = ref.watch(canteenApplicationSubmitProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buka Kantin'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            Text(
              'Ajukan Buka Kantin',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lengkapi informasi kantin yang ingin kamu buka. '
              'Pengajuan akan ditinjau oleh admin.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            KcTextField(
              controller: _nameController,
              label: 'Nama Kantin',
              hint: 'Contoh: Kantin Berkah',
              prefixIcon: Icons.storefront_outlined,
              textInputAction: TextInputAction.next,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            KcTextField(
              controller: _descriptionController,
              label: 'Deskripsi',
              hint: 'Ceritakan sedikit tentang kantin kamu',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.next,
              errorText: _descriptionError,
              onChanged: (_) {
                if (_descriptionError != null) {
                  setState(() => _descriptionError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            KcTextField(
              controller: _addressController,
              label: 'Alamat Kantin',
              hint: 'Masukkan alamat kantin',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 3,
              keyboardType: TextInputType.streetAddress,
              errorText: _addressError,
              onChanged: (_) {
                if (_addressError != null) {
                  setState(() => _addressError = null);
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: KcButton(
            label: 'Ajukan Pengajuan',
            onPressed: _submit,
            leading: const Icon(Icons.send_outlined),
            isLoading: isSubmitting,
          ),
        ),
      ),
    );
  }
}

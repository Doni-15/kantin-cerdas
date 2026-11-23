import 'package:flutter/material.dart';
import 'package:kantin_cerdas/widgets/kc_dialogs.dart';

Future<bool> confirmPhotoChange(
  BuildContext context, {
  required String title,
  required String description,
}) => showKcConfirmDialog(
  context,
  title: title,
  message: description,
  confirmLabel: 'Ganti foto',
);

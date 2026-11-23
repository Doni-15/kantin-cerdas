import 'package:flutter/material.dart';

String formatRupiah(BuildContext context, int amount) {
  final formatted = MaterialLocalizations.of(context).formatDecimal(amount);
  return 'Rp$formatted';
}

String formatOrderTime(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

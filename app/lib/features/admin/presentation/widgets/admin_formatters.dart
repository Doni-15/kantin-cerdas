String formatAdminDate(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String adminWeekdayName(int dayOfWeek) => switch (dayOfWeek) {
  1 => 'Senin',
  2 => 'Selasa',
  3 => 'Rabu',
  4 => 'Kamis',
  5 => 'Jumat',
  6 => 'Sabtu',
  7 => 'Minggu',
  _ => 'Hari $dayOfWeek',
};

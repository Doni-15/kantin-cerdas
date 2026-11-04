import 'package:intl/intl.dart';

final _wibFormat = DateFormat('dd/MM/yyyy HH:mm');

String formatWib(DateTime value) {
  final wib = value.toUtc().add(const Duration(hours: 7));
  return '${_wibFormat.format(wib)} WIB';
}

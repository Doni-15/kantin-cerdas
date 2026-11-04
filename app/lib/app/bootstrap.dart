import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kantin_cerdas/app/production_overrides.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';

Future<List<Override>> bootstrap() async {
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';
  final storage = await LocalStorage.create();

  return <Override>[
    localStorageProvider.overrideWithValue(storage),
    ...buildProductionOverrides(),
  ];
}

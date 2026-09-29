import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';
import 'package:kantin_cerdas/kantin_cerdas_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('KantinCerdas app dapat ditampilkan', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // SharedPreferences memakai async nyata; di dalam testWidgets harus lewat
    // runAsync agar tidak tertahan oleh fake async.
    final storage = await tester.runAsync(LocalStorage.create);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage!)],
        child: const KantinCerdasApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Belum ada sesi -> router menampilkan halaman login.
    expect(find.text('KantinCerdas'), findsWidgets);
  });
}

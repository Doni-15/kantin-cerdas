import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_presentation.dart';
import 'package:kantin_cerdas/widgets/kc_inline_progress_indicator.dart';
import 'package:kantin_cerdas/widgets/kc_search_field.dart';

void main() {
  group('KcSearchField reusable widget invariants', () {
    testWidgets(
      'supports typing, submit, clear action, debounce, and external focus/controller preservation',
      (tester) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        addTearDown(() {
          controller.dispose();
          focusNode.dispose();
        });

        final submitted = <String>[];
        final debouncedQueries = <String>[];
        Timer? debounce;
        addTearDown(() => debounce?.cancel());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return KcSearchField(
                    controller: controller,
                    focusNode: focusNode,
                    hintText: 'Cari kantin...',
                    maxLength: 100,
                    hideCounter: true,
                    clearTooltip: 'Hapus pencarian',
                    clearIcon: Icons.close,
                    showClearButton: controller.text.isNotEmpty,
                    onChanged: (value) {
                      setState(() {});
                      debounce?.cancel();
                      debounce = Timer(const Duration(milliseconds: 250), () {
                        debouncedQueries.add(value.trim());
                      });
                    },
                    onSubmitted: submitted.add,
                    onClear: () {
                      controller.clear();
                      debounce?.cancel();
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(find.byTooltip('Hapus pencarian'), findsNothing);

        await tester.tap(find.byType(TextField));
        await tester.pump();
        expect(focusNode.hasFocus, isTrue);

        await tester.enterText(find.byType(TextField), 'soto');
        await tester.pump();
        expect(find.byTooltip('Hapus pencarian'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);

        // Rapid edit resets debounce timer so only the final query runs.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(find.byType(TextField), 'soto ayam');
        await tester.pump(const Duration(milliseconds: 260));
        expect(debouncedQueries, ['soto ayam']);

        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        expect(submitted, ['soto ayam']);

        // Clear cancels any pending debounce and clears controller text.
        await tester.enterText(find.byType(TextField), 'bakso');
        await tester.pump();
        await tester.tap(find.byTooltip('Hapus pencarian'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(controller.text, isEmpty);
        expect(debouncedQueries, ['soto ayam']);
        expect(find.byTooltip('Hapus pencarian'), findsNothing);

        // Unmounting KcSearchField must not dispose external controller/focus.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        expect(() => controller.text = 'masih aktif', returnsNormally);
        expect(focusNode.canRequestFocus, isTrue);
      },
    );
  });

  group('KcInlineProgressIndicator invariants', () {
    testWidgets('renders default 18px and custom 14px/16px spinners', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KcInlineProgressIndicator(),
                KcInlineProgressIndicator(size: 16),
                KcInlineProgressIndicator(size: 14),
              ],
            ),
          ),
        ),
      );

      final boxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.width != null && b.height != null)
          .toList();
      expect(boxes.map((b) => b.width).toList(), [18, 16, 14]);
      expect(boxes.map((b) => b.height).toList(), [18, 16, 14]);
      for (final indicator in tester.widgetList<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      )) {
        expect(indicator.strokeWidth, 2);
      }
    });
  });

  group('AuthCredentialsForm modular mode composition invariants', () {
    testWidgets(
      'preserves mode transitions, password toggle, validation, in-memory verify credential, and clean disposal',
      (tester) async {
        final calls = <String>[];
        final store = MemorySessionStore();
        final client = MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.url.path == '/v1/auth/register') {
            return http.Response(
              jsonEncode({'success': true, 'data': null}),
              200,
            );
          }
          if (request.url.path == '/v1/auth/login') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['email'], 'mahasiswa@kampus.ac.id');
            expect(body['password'], 'rahasia-sangat-panjang-15');
            return http.Response(
              jsonEncode({
                'success': false,
                'error': {
                  'code': 'EMAIL_NOT_VERIFIED',
                  'message': 'Verifikasi email diperlukan.',
                },
              }),
              403,
            );
          }
          if (request.url.path == '/v1/auth/password-reset') {
            return http.Response(
              jsonEncode({'success': true, 'data': null}),
              200,
            );
          }
          return http.Response(
            jsonEncode({'success': true, 'data': null}),
            200,
          );
        });
        addTearDown(client.close);

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(
                client: client,
                store: store,
                baseUrl: 'https://api.example.test',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: AuthCredentialsForm()),
          ),
        );

        Future<void> tapVisible(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pump();
          await tester.tap(finder);
        }

        // 1. Login validation and password visibility toggle.
        expect(find.text('Selamat datang kembali'), findsOneWidget);
        await tapVisible(find.widgetWithText(FilledButton, 'Masuk'));
        await tester.pump();
        expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
        expect(find.text('Masukkan password.'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('auth-email')),
          'mahasiswa@kampus.ac.id',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth-password')),
          'pendek',
        );
        await tester.pump();

        expect(find.byTooltip('Tampilkan kata sandi'), findsOneWidget);
        await tapVisible(find.byTooltip('Tampilkan kata sandi'));
        await tester.pump();
        expect(find.byTooltip('Sembunyikan kata sandi'), findsOneWidget);

        // 2. Login -> Registration preserves email, clears password, enforces >=15 chars.
        await tapVisible(find.widgetWithText(TextButton, 'Daftar'));
        await tester.pump();
        expect(find.text('Buat akun'), findsOneWidget);
        expect(find.text('Langkah 1 dari 2'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const ValueKey('auth-email')))
              .controller
              ?.text,
          'mahasiswa@kampus.ac.id',
        );
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('auth-password')),
              )
              .controller
              ?.text,
          isEmpty,
        );

        await tester.enterText(
          find.byKey(const ValueKey('auth-registration-name')),
          'Budi Mahasiswa',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth-password')),
          'kurang15',
        );
        await tapVisible(find.widgetWithText(FilledButton, 'Lanjutkan'));
        await tester.pump();
        expect(find.text('Gunakan minimal 15 karakter.'), findsOneWidget);

        // 3. Valid registration transitions to Email Verification keeping password in memory.
        await tester.enterText(
          find.byKey(const ValueKey('auth-password')),
          'rahasia-sangat-panjang-15',
        );
        await tapVisible(find.widgetWithText(FilledButton, 'Lanjutkan'));
        await tester.pumpAndSettle();
        expect(find.text('Cek email kamu'), findsOneWidget);
        expect(find.text('mahasiswa@kampus.ac.id'), findsOneWidget);

        await tapVisible(
          find.widgetWithText(FilledButton, 'Saya sudah verifikasi'),
        );
        await tester.pumpAndSettle();
        expect(calls, ['POST /v1/auth/register', 'POST /v1/auth/login']);

        // 4. Verify -> Login -> Password Reset -> Login.
        await tapVisible(find.widgetWithText(TextButton, 'Kembali ke Masuk'));
        await tester.pump();
        expect(find.text('Selamat datang kembali'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('auth-password')),
              )
              .controller
              ?.text,
          isEmpty,
        );

        await tapVisible(find.widgetWithText(TextButton, 'Lupa password?'));
        await tester.pump();
        expect(find.text('Pemulihan akun'), findsOneWidget);
        await tapVisible(
          find.widgetWithText(FilledButton, 'Kirim tautan reset'),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Jika alamat email terdaftar'),
          findsOneWidget,
        );
        expect(calls.last, 'POST /v1/auth/password-reset');

        await tapVisible(find.widgetWithText(TextButton, 'Masuk'));
        await tester.pump();
        expect(find.text('Selamat datang kembali'), findsOneWidget);

        // 5. Clean disposal of AuthCredentialsForm controllers.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await tester.pumpAndSettle();
      },
    );
  });
}

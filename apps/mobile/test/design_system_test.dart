import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantincerdas/app/theme/kantin_cerdas_theme.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_colors.dart';
import 'package:kantincerdas/shared/widgets/kc_button.dart';
import 'package:kantincerdas/shared/widgets/kc_fields.dart';
import 'package:kantincerdas/shared/widgets/kc_filter_bar.dart';
import 'package:kantincerdas/shared/widgets/kc_overlays.dart';
import 'package:kantincerdas/shared/widgets/kc_state_view.dart';

Widget host(
  Widget child, {
  bool dark = false,
  double scale = 1,
  bool reduceMotion = false,
  double keyboard = 0,
}) {
  return MaterialApp(
    theme: dark ? KantinCerdasTheme.dark : KantinCerdasTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduceMotion,
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
      child: child!,
    ),
    home: Scaffold(body: SafeArea(child: child)),
  );
}

void main() {
  test('kontras teks tema dan pasangan status minimal 4.5:1', () {
    final pairs = <(Color, Color)>[
      (KantinCerdasColors.available, KantinCerdasColors.availableContainer),
      (KantinCerdasColors.waitingText, KantinCerdasColors.waitingContainer),
      (KantinCerdasColors.processing, KantinCerdasColors.processingContainer),
      (KantinCerdasColors.ready, KantinCerdasColors.readyContainer),
      (KantinCerdasColors.completed, KantinCerdasColors.completedContainer),
      (KantinCerdasColors.rejected, KantinCerdasColors.rejectedContainer),
    ];
    for (final colors in [
      KantinCerdasColors.lightScheme,
      KantinCerdasColors.darkScheme,
    ]) {
      pairs.addAll([
        (colors.onSurface, colors.surface),
        (colors.onSurfaceVariant, colors.surface),
        (colors.onSurfaceVariant, colors.surfaceContainerHighest),
        (colors.onPrimary, colors.primary),
        (colors.onError, colors.error),
        (colors.onErrorContainer, colors.errorContainer),
        (colors.onSecondaryContainer, colors.secondaryContainer),
        (colors.onInverseSurface, colors.inverseSurface),
        (colors.inversePrimary, colors.inverseSurface),
      ]);
    }
    for (final (foreground, background) in pairs) {
      final a = foreground.computeLuminance();
      final b = background.computeLuminance();
      final ratio = a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: '$foreground/$background',
      );
    }
  });

  testWidgets('loading dan disabled mencegah aksi ganda; motion dihormati', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            KcButton(label: 'Tambah', onPressed: () => calls++),
            KcButton(label: 'Simpan', loading: true, onPressed: () => calls++),
            const KcButton(label: 'Nonaktif', onPressed: null),
          ],
        ),
        reduceMotion: true,
      ),
    );
    await tester.tap(find.text('Tambah'));
    await tester.tap(find.text('Simpan — Memproses'));
    await tester.tap(find.text('Nonaktif'));
    expect(calls, 1);
    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(progress.value, isNotNull);
    for (final button in tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    )) {
      expect(button.style!.animationDuration, Duration.zero);
    }
    await tester.pumpAndSettle();
  });

  for (final dark in [false, true]) {
    testWidgets('target sentuh dan label tombol/chip/input, dark=$dark', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final controller = TextEditingController(text: 'Nasi');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final variant in KcButtonVariant.values)
                KcButton(
                  label: variant.name,
                  variant: variant,
                  onPressed: () {},
                ),
              KcSearchField(controller: controller, onChanged: (_) {}),
              KcFilterBar(
                options: const ['Nasi', 'Mi'],
                selected: const {'Nasi'},
                onSelected: (_, _) {},
              ),
            ],
          ),
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      final colors = dark
          ? KantinCerdasColors.darkScheme
          : KantinCerdasColors.lightScheme;
      for (final variant in KcButtonVariant.values) {
        final filled = variant == KcButtonVariant.primary;
        final destructive = variant == KcButtonVariant.destructive;
        final foreground = destructive
            ? colors.onError
            : filled
            ? colors.onPrimary
            : colors.primary;
        final background = destructive
            ? colors.error
            : filled
            ? colors.primary
            : colors.surface;
        final control = tester.widget<ButtonStyleButton>(
          find.descendant(
            of: find.widgetWithText(KcButton, variant.name),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
        );
        for (final state in [WidgetState.pressed, WidgetState.focused]) {
          final overlay = control.style!.overlayColor!.resolve({state})!;
          final blended = Color.alphaBlend(overlay, background);
          final a = foreground.computeLuminance();
          final b = blended.computeLuminance();
          final ratio = a > b
              ? (a + 0.05) / (b + 0.05)
              : (b + 0.05) / (a + 0.05);
          expect(ratio, greaterThanOrEqualTo(4.5));
        }
      }
    });
  }

  testWidgets(
    'pencarian dapat dihapus dan validasi input mempertahankan teks',
    (tester) async {
      final controller = TextEditingController();
      final input = TextEditingController();
      addTearDown(controller.dispose);
      addTearDown(input.dispose);
      var query = '';
      await tester.pumpWidget(
        host(
          Column(
            children: [
              KcSearchField(
                controller: controller,
                onChanged: (v) => query = v,
              ),
              KcInput(
                label: 'Catatan',
                controller: input,
                validator: (v) => v == '!' ? 'Isi catatan yang jelas.' : null,
              ),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Nasi');
      expect(query, 'Nasi');
      await tester.pump();
      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pump();
      expect(query, '');
      expect(controller.text, '');
      expect(find.byTooltip('Hapus pencarian'), findsNothing);
      await tester.enterText(find.byType(TextFormField), '!');
      await tester.pump();
      expect(find.text('Isi catatan yang jelas.'), findsOneWidget);
      expect(input.text, '!');
    },
  );

  testWidgets(
    'Tab mengikuti urutan kontrol, fokus terlihat, Enter mengaktifkan',
    (tester) async {
      final first = FocusNode();
      final second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var calls = 0;
      await tester.pumpWidget(
        host(
          FocusTraversalGroup(
            child: Column(
              children: [
                KcButton(label: 'Pertama', focusNode: first, onPressed: () {}),
                KcButton(
                  label: 'Kedua',
                  focusNode: second,
                  onPressed: () => calls++,
                ),
              ],
            ),
          ),
        ),
      );
      first.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(second.hasFocus, isTrue);
      final button = tester.widget<FilledButton>(
        find.byType(FilledButton).last,
      );
      expect(button.style!.side!.resolve({WidgetState.focused})!.width, 2);
      expect(
        button.style!.overlayColor!.resolve({WidgetState.pressed}),
        isNotNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, 1);
    },
  );

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(800, 360),
  ]) {
    testWidgets('komponen tidak overflow pada $size dengan teks 200%', (
      tester,
    ) async {
      tester.view.reset();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final variant in KcButtonVariant.values)
                  KcButton(
                    label: 'Tambahkan pilihan makanan ke keranjang',
                    variant: variant,
                    onPressed: () {},
                  ),
                KcSearchField(controller: controller, onChanged: (_) {}),
                KcInput(label: 'Catatan', controller: controller),
                KcFilterBar(
                  options: const ['Nasi', 'Minuman', 'Camilan'],
                  selected: const {},
                  onSelected: (_, _) {},
                ),
                for (final state in KcViewState.values)
                  KcStateView(
                    state: state,
                    title: 'Status pilihan makanan',
                    message:
                        'Kamu tetap bisa mencari dan memilih secara manual.',
                    actionLabel: 'Coba lagi',
                    onAction: () {},
                  ),
              ],
            ),
          ),
          scale: 2,
          reduceMotion: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('error bisa retry; offline mempertahankan konten tersimpan', (
    tester,
  ) async {
    var retry = 0;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            KcStateView(
              state: KcViewState.error,
              title: 'Gagal memuat',
              message: 'Coba lagi.',
              actionLabel: 'Coba lagi',
              onAction: () => retry++,
            ),
            const KcStateView(
              state: KcViewState.offline,
              title: 'Offline',
              message: 'Data tersimpan.',
              child: Text('Menu tersimpan'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Coba lagi'));
    expect(retry, 1);
    expect(find.text('Menu tersimpan'), findsOneWidget);
  });

  testWidgets('dialog batal aman dan mengembalikan fokus ke pemicu', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => KcButton(
            label: 'Buka dialog',
            focusNode: focus,
            onPressed: () async {
              result = await showKcConfirmation(
                context: context,
                title: 'Kosongkan?',
                message: 'Pilihan akan dihapus.',
                confirmLabel: 'Kosongkan',
                destructive: true,
              );
            },
          ),
        ),
        reduceMotion: true,
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('sheet dapat digulir dengan keyboard dan teks besar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => KcButton(
            label: 'Buka sheet',
            onPressed: () => showKcBottomSheet<void>(
              context: context,
              title: 'Pilihan makanan',
              builder: (context) => Column(
                children: [
                  KcInput(label: 'Catatan', controller: controller),
                  for (var i = 0; i < 6; i++) const Text('Pilihan makanan'),
                  KcButton(
                    label: 'Simpan',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
        scale: 2,
        reduceMotion: true,
        keyboard: 300,
      ),
    );
    await tester.tap(find.text('Buka sheet'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });
}

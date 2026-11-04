import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/food_preferences_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/preferences/food_preferences_fields.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/preferences/food_preferences_discard_dialog.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class FoodPreferencesForm extends ConsumerStatefulWidget {
  const FoodPreferencesForm({
    super.key,
    required this.snapshot,
    required this.onReload,
    required this.onClose,
    this.pending,
  });
  final FoodPreferencesSnapshot? snapshot;
  final FoodPreferences? pending;
  final VoidCallback onReload;
  final VoidCallback onClose;
  @override
  ConsumerState<FoodPreferencesForm> createState() =>
      FoodPreferencesFormState();
}

class FoodPreferencesFormState extends ConsumerState<FoodPreferencesForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _budget;
  late final TextEditingController _ingredients;
  late bool _vegetarian;
  bool _edited = false;
  bool _saving = false;
  bool _confirming = false;
  bool _allowPop = false;
  bool _leaving = false;
  @override
  void initState() {
    super.initState();
    final value = widget.pending ?? widget.snapshot?.preferences;
    _budget = TextEditingController(
      text: value?.maxBudgetIdr?.toString() ?? '',
    );
    _ingredients = TextEditingController(
      text: value?.avoidIngredients.join(', ') ?? '',
    );
    _vegetarian = value?.vegetarian ?? false;
  }

  @override
  void didUpdateWidget(covariant FoodPreferencesForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jurnal dapat selesai dibaca setelah data layanan. Jangan timpa isian yang diedit.
    final pending = widget.pending;
    if (!_edited && oldWidget.pending == null && pending != null) {
      _budget.text = pending.maxBudgetIdr?.toString() ?? '';
      _ingredients.text = pending.avoidIngredients.join(', ');
      _vegetarian = pending.vegetarian;
    }
  }

  @override
  void dispose() {
    _budget.dispose();
    _ingredients.dispose();
    super.dispose();
  }

  FoodPreferences _value() => FoodPreferences(
    maxBudgetIdr: FoodPreferences.parseBudget(_budget.text),
    vegetarian: _vegetarian,
    avoidIngredients: FoodPreferences.parseIngredients(_ingredients.text),
  );
  bool get _dirty {
    final saved =
        widget.snapshot?.preferences ??
        FoodPreferences(
          maxBudgetIdr: null,
          vegetarian: false,
          avoidIngredients: const [],
        );
    try {
      return !_value().sameAs(saved);
    } on ArgumentError {
      return true;
    }
  }

  bool get _unsaved {
    final state = ref.read(foodPreferencesSaveProvider);
    // Snapshot yang sudah dikirim tersimpan di jurnal, bukan draft yang hilang saat keluar.
    return _dirty && state.pending == null && !state.saved;
  }

  void _changed() {
    _edited = true;
    ref.read(foodPreferencesControllerProvider.notifier).clearNotice();
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving ||
        _confirming ||
        _leaving ||
        ref.read(foodPreferencesSaveProvider).blocked ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final revision = ref.read(foodPreferencesSaveProvider).revision;
    final input = FoodPreferencesUpdate(
      preferences: _value(),
      expectedVersion: widget.snapshot?.version,
    );
    setState(() => _saving = true);
    try {
      await ref
          .read(foodPreferencesControllerProvider.notifier)
          .save(input, revision: revision);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _confirm({required bool reload}) async {
    if (_saving ||
        _confirming ||
        _leaving ||
        ref.read(foodPreferencesSaveProvider).busy) {
      return false;
    }
    if (!_unsaved) {
      return true;
    }
    setState(() => _confirming = true);
    try {
      return await confirmFoodPreferencesDiscard(context, ref, reload: reload);
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  Future<void> requestClose() async {
    final session = KcRoleSession(ref, role: UserRole.customer);
    if (!await _confirm(reload: false) || !mounted || !session.isCurrent(ref)) {
      return;
    }
    setState(() {
      _allowPop = true;
      _leaving = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          session.isCurrent(ref) &&
          ModalRoute.of(context)?.isCurrent == true) {
        widget.onClose();
      }
    });
  }

  Future<void> _reload() async {
    final session = KcRoleSession(ref, role: UserRole.customer);
    final revision = ref.read(foodPreferencesSaveProvider).revision;
    if (!await _confirm(reload: true) ||
        !mounted ||
        !session.isCurrent(ref) ||
        ref.read(foodPreferencesSaveProvider).revision != revision) {
      return;
    }
    widget.onReload();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodPreferencesSaveProvider);
    final localBusy = _saving || _confirming || _leaving;
    final reloadEnabled =
        !localBusy &&
        !state.busy &&
        state.pending == null &&
        !state.journalLoading &&
        state.journalError == null;
    return Form(
      key: _form,
      canPop: _allowPop || (!_unsaved && !localBusy && !state.busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          requestClose();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.snapshot == null) ...[
            const Text(
              'Belum ada preferensi tersimpan. Isi pilihanmu lalu simpan.',
            ),
            const SizedBox(height: KcSpacing.md),
          ],
          FoodPreferencesFields(
            budget: _budget,
            ingredients: _ingredients,
            vegetarian: _vegetarian,
            enabled: !state.blocked && !localBusy,
            onChanged: _changed,
            onVegetarianChanged: (value) {
              _vegetarian = value;
              _changed();
            },
          ),
          const SizedBox(height: KcSpacing.lg),
          KcButton(
            label: 'Simpan preferensi',
            isLoading: state.busy,
            onPressed:
                state.blocked ||
                    localBusy ||
                    (widget.snapshot != null && !_dirty)
                ? null
                : _save,
          ),
          const SizedBox(height: KcSpacing.sm),
          TextButton.icon(
            onPressed: reloadEnabled ? _reload : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat data terbaru'),
          ),
        ],
      ),
    );
  }
}

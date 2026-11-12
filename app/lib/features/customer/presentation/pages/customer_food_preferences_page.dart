import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/food_preferences_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/food_preferences_message.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/food_preferences_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/preferences/food_preferences_form.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/preferences/food_preferences_notice.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerFoodPreferencesPage extends ConsumerWidget {
  const CustomerFoodPreferencesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    final session = ref.watch(authStateProvider.notifier);
    if (auth.isLoading ||
        auth.hasError ||
        user == null ||
        !user.isActive ||
        !user.role.canUseCustomerFeatures) {
      return const Scaffold(
        body: SafeArea(
          child: KcStatusPanel(
            title: 'Sesi pelanggan diperlukan',
            message: 'Masuk kembali untuk mengatur preferensi makanan.',
          ),
        ),
      );
    }
    return _FoodPreferencesBody(
      key: ValueKey((user.id, session, session.sessionGeneration)),
    );
  }
}

class _FoodPreferencesBody extends ConsumerStatefulWidget {
  const _FoodPreferencesBody({super.key});
  @override
  ConsumerState<_FoodPreferencesBody> createState() =>
      _FoodPreferencesBodyState();
}

class _FoodPreferencesBodyState extends ConsumerState<_FoodPreferencesBody> {
  GlobalKey<FoodPreferencesFormState> _formKey =
      GlobalKey<FoodPreferencesFormState>();
  int? _revision;
  int? _version;
  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.customerProfile);
    }
  }

  void _requestClose() {
    final form = _formKey.currentState;
    if (form != null) {
      form.requestClose();
    } else if (!ref.read(foodPreferencesSaveProvider).busy) {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(foodPreferencesSaveProvider);
    final data = ref.watch(foodPreferencesProvider);
    final version = data.asData?.value?.version;
    if (_revision != save.revision || _version != version) {
      _formKey = GlobalKey<FoodPreferencesFormState>();
      _revision = save.revision;
      _version = version;
    }
    void reload() =>
        ref.read(foodPreferencesControllerProvider.notifier).refreshData();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferensi makanan'),
        leading: BackButton(onPressed: _requestClose),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(KcSpacing.lg),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const Text(
                  'Atur pilihan makanan untuk membantu rekomendasi menu pada akunmu.',
                ),
                const SizedBox(height: KcSpacing.md),
                if (save.hasNotice) ...[
                  FoodPreferencesNotice(
                    state: save,
                    onRecover: save.busy
                        ? null
                        : () => ref
                              .read(foodPreferencesControllerProvider.notifier)
                              .recover(),
                    onReloadJournal: save.busy
                        ? null
                        : () => ref
                              .read(foodPreferencesControllerProvider.notifier)
                              .reloadJournal(),
                  ),
                  const SizedBox(height: KcSpacing.md),
                ],
                data.when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () => const KcLoadingSkeleton(
                    label: 'Memuat preferensi',
                    layout: KcSkeletonLayout.form,
                  ),
                  error: (error, _) => KcStatusPanel(
                    title: 'Preferensi belum tersedia',
                    message: foodPreferencesMessage(error),
                    action: error is FoodPreferencesNotConfiguredFailure
                        ? null
                        : TextButton(
                            onPressed: save.busy ? null : reload,
                            child: const Text('Coba lagi'),
                          ),
                  ),
                  data: (snapshot) => FoodPreferencesForm(
                    key: _formKey,
                    snapshot: snapshot,
                    pending: save.pendingPreferences,
                    onReload: reload,
                    onClose: _close,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

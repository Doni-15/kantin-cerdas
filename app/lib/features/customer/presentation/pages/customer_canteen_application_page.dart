import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/canteen_application_submit_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_feature_error.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/application/canteen_application_form.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/application/canteen_application_notice.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/application/canteen_application_status_card.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerCanteenApplicationPage extends ConsumerWidget {
  const CustomerCanteenApplicationPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final session = ref.watch(authStateProvider.notifier);
    final user = auth.asData?.value;
    if (auth.isLoading ||
        auth.hasError ||
        user == null ||
        !user.isActive ||
        !user.role.canUseCustomerFeatures) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(KcSpacing.lg),
            child: KcLoadingSkeleton(
              label: 'Memeriksa sesi',
              layout: KcSkeletonLayout.form,
            ),
          ),
        ),
      );
    }
    return _ApplicationPageBody(
      key: ValueKey((user.id, session, session.sessionGeneration)),
      customerId: user.id,
    );
  }
}

class _ApplicationPageBody extends ConsumerStatefulWidget {
  const _ApplicationPageBody({super.key, required this.customerId});
  final String customerId;
  @override
  ConsumerState<_ApplicationPageBody> createState() =>
      _ApplicationPageBodyState();
}

class _ApplicationPageBodyState extends ConsumerState<_ApplicationPageBody> {
  GlobalKey<CanteenApplicationFormState> _form =
      GlobalKey<CanteenApplicationFormState>();
  (String?, int?)? _formIdentity;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.customerProfile);
    }
  }

  void _requestClose() {
    final form = _form.currentState;
    if (form != null) {
      form.requestClose();
    } else {
      _close();
    }
  }

  Future<void> _refresh() async {
    final form = _form.currentState;
    if (form != null && !await form.confirmDiscard()) {
      return;
    }
    if (!mounted) {
      return;
    }
    await ref
        .read(canteenApplicationSubmitProvider.notifier)
        .reloadApplication();
  }

  Widget _content(CanteenApplication? application) {
    final identity = (application?.id, application?.version);
    if (_formIdentity != identity) {
      _formIdentity = identity;
      _form = GlobalKey<CanteenApplicationFormState>();
    }
    final busy = ref.watch(canteenApplicationSubmitProvider).busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (application != null) ...[
          CanteenApplicationStatusCard(application: application),
          const SizedBox(height: KcSpacing.md),
        ],
        if (ref.watch(authStateProvider).asData?.value?.role ==
                UserRole.customer &&
            (application == null ||
                application.status == CanteenApplicationStatus.rejected))
          CanteenApplicationForm(
            key: _form,
            customerId: widget.customerId,
            previous: application,
            onClose: _close,
          )
        else
          OutlinedButton.icon(
            onPressed: busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Perbarui status'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final application = ref.watch(canteenApplicationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan kantin'),
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
                  'Ajukan usaha kantinmu untuk ditinjau oleh admin kampus.',
                ),
                const SizedBox(height: KcSpacing.md),
                CanteenApplicationNotice(
                  customerId: widget.customerId,
                  onRefresh: _refresh,
                ),
                const SizedBox(height: KcSpacing.md),
                application.when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () => const KcLoadingSkeleton(
                    label: 'Memuat pengajuan',
                    layout: KcSkeletonLayout.form,
                  ),
                  error: (error, _) =>
                      CustomerFeatureError(error: error, onRetry: _refresh),
                  data: _content,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

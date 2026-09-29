import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/profile/canteen_application_error_screen.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/profile/canteen_application_form_screen.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/profile/canteen_application_loading_screen.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/profile/canteen_application_status_screen.dart';

class CustomerCanteenApplicationPage extends ConsumerWidget {
  const CustomerCanteenApplicationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(canteenApplicationProvider).when(
          loading: () => const CanteenApplicationLoadingScreen(),
          error: (error, stackTrace) =>
              CanteenApplicationErrorScreen(error: error),
          data: (application) {
            if (application == null) {
              return const CanteenApplicationFormScreen();
            }

            return CanteenApplicationStatusScreen(application: application);
          },
        );
  }
}
